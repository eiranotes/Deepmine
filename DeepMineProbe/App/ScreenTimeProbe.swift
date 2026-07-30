import Combine
import DeviceActivity
@preconcurrency import FamilyControls
import Foundation
import ManagedSettings

enum ScreenTimeProbeError: LocalizedError {
    case authorizationRequired(AuthorizationStatus)
    case emptySelection

    var errorDescription: String? {
        switch self {
        case .authorizationRequired(let status):
            "방해 앱을 가리려면 차단 권한이 필요합니다. 현재 상태: \(status.description)"
        case .emptySelection:
            "차단할 앱이나 카테고리를 먼저 선택해 주세요."
        }
    }
}

struct ShieldApplicationResult: Sendable {
    let elapsed: TimeInterval
    let expiresAt: Date
}

@MainActor
protocol ScreenTimeSelectionStoring {
    func load() throws -> FamilyActivitySelection
    func save(_ selection: FamilyActivitySelection) throws
}

@MainActor
struct SharedScreenTimeSelectionStorage: ScreenTimeSelectionStoring {
    func load() throws -> FamilyActivitySelection {
        let directory = try ProbeSharedStores.directoryURL()
        let url = directory.appending(path: ProbeConstants.selectionFilename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return FamilyActivitySelection()
        }
        return try JSONDecoder().decode(
            FamilyActivitySelection.self,
            from: Data(contentsOf: url)
        )
    }

    func save(_ selection: FamilyActivitySelection) throws {
        let directory = try ProbeSharedStores.directoryURL()
        let data = try JSONEncoder().encode(selection)
        try data.write(
            to: directory.appending(path: ProbeConstants.selectionFilename),
            options: .atomic
        )
    }
}

@MainActor
final class ScreenTimeProbe: ObservableObject {
    @Published var selection: FamilyActivitySelection
    @Published private(set) var initializationError: String?

    private let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name(ProbeConstants.shieldStoreName)
    )
    private let center = DeviceActivityCenter()
    private let selectionStorage: any ScreenTimeSelectionStoring

    init(storage: any ScreenTimeSelectionStoring = SharedScreenTimeSelectionStorage()) {
        selectionStorage = storage
        do {
            selection = try storage.load()
            initializationError = nil
        } catch {
            selection = FamilyActivitySelection()
            initializationError = ProbeDiagnostics.safeSummary(for: error)
            ProbeDiagnostics.record(error: error, source: "FamilySelectionLoad")
        }
    }

    func requestAuthorization() async throws -> AuthorizationStatus {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        return AuthorizationCenter.shared.authorizationStatus
    }

    func persistSelection() throws {
        try replaceSelection(selection)
    }

    func replaceSelection(_ newSelection: FamilyActivitySelection) throws {
        try selectionStorage.save(newSelection)
        selection = newSelection
    }

    func applyShields() throws -> ShieldApplicationResult {
        let startsAt = Date()
        return try applyShields(
            sessionID: nil,
            startsAt: startsAt,
            expiresAt: startsAt.addingTimeInterval(ProbeConstants.probeDuration)
        )
    }

    func applyShields(
        sessionID: UUID?, startsAt: Date, expiresAt: Date
    ) throws -> ShieldApplicationResult {
        let status = AuthorizationCenter.shared.authorizationStatus
        guard Self.isAuthorized(status) else {
            throw ScreenTimeProbeError.authorizationRequired(status)
        }
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            throw ScreenTimeProbeError.emptySelection
        }

        let startedAt = DispatchTime.now().uptimeNanoseconds
        let activity = DeviceActivityName(
            "\(ProbeConstants.activityName).\(UUID().uuidString)"
        )
        let lock = try ProbeProcessLock.acquire(
            filename: ProbeConstants.shieldLifecycleLockFilename
        )
        defer { lock.release() }

        do {
            stopAllProbeMonitoring()
            store.clearAllSettings()
            try ProbeShieldJournal.remove()
            try scheduleMonitorBoundary(
                activity: activity,
                startsAt: startsAt,
                expiresAt: expiresAt
            )
            try ProbeShieldJournal.save(
                ProbeShieldExpiry(
                    sessionID: sessionID,
                    activityName: activity.rawValue,
                    expiresAt: expiresAt
                )
            )
            store.shield.applications = selection.applicationTokens.isEmpty
                ? nil
                : selection.applicationTokens
            store.shield.applicationCategories = selection.categoryTokens.isEmpty
                ? nil
                : .specific(selection.categoryTokens)
        } catch {
            center.stopMonitoring([activity])
            store.clearAllSettings()
            do {
                try ProbeShieldJournal.removeIfMatching(activityName: activity.rawValue)
            } catch let rollbackError {
                ProbeDiagnostics.record(
                    error: rollbackError,
                    source: "ShieldRollbackJournal"
                )
            }
            throw error
        }

        let elapsed = TimeInterval(DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000_000
        return ShieldApplicationResult(elapsed: elapsed, expiresAt: expiresAt)
    }

    func clearShields() throws -> TimeInterval {
        let startedAt = DispatchTime.now().uptimeNanoseconds
        let lock = try ProbeProcessLock.acquire(
            filename: ProbeConstants.shieldLifecycleLockFilename
        )
        defer { lock.release() }
        stopAllProbeMonitoring()
        store.clearAllSettings()
        try ProbeShieldJournal.remove()
        let finishedAt = DispatchTime.now().uptimeNanoseconds
        return TimeInterval(finishedAt - startedAt) / 1_000_000_000
    }

    func clearShields(sessionID: UUID) throws -> TimeInterval? {
        let startedAt = DispatchTime.now().uptimeNanoseconds
        let lock = try ProbeProcessLock.acquire(
            filename: ProbeConstants.shieldLifecycleLockFilename
        )
        defer { lock.release() }
        guard let expiry = try ProbeShieldJournal.load(),
              expiry.sessionID == sessionID else { return nil }
        center.stopMonitoring([DeviceActivityName(expiry.activityName)])
        store.clearAllSettings()
        try ProbeShieldJournal.removeIfMatching(activityName: expiry.activityName)
        return TimeInterval(DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000_000
    }

    func shieldIntegrity(sessionID: UUID) -> SessionShieldIntegrity {
        guard Self.isAuthorized(AuthorizationCenter.shared.authorizationStatus) else {
            return .removed
        }
        guard let expiry = try? ProbeShieldJournal.load(),
              expiry.sessionID == sessionID else { return .removed }
        let activity = DeviceActivityName(expiry.activityName)
        return expiry.expiresAt > Date() && center.activities.contains(activity)
            ? .maintained
            : .removed
    }

    func recoverExpiredShieldIfNeeded(now: Date = Date()) throws -> String? {
        let lock = try ProbeProcessLock.acquire(
            filename: ProbeConstants.shieldLifecycleLockFilename
        )
        defer { lock.release() }
        guard let expiry = try ProbeShieldJournal.load() else {
            let hadOrphanedMonitor = !probeActivities.isEmpty
            stopAllProbeMonitoring()
            store.clearAllSettings()
            return hadOrphanedMonitor
                ? "남아 있던 갱도 문을 안전하게 열었어요 · 해제 기록 없음"
                : nil
        }
        let activity = DeviceActivityName(expiry.activityName)
        let monitorIsActive = center.activities.contains(activity)
        guard expiry.expiresAt <= now || !monitorIsActive else { return nil }

        center.stopMonitoring([activity])
        store.clearAllSettings()
        try ProbeShieldJournal.removeIfMatching(activityName: activity.rawValue)
        let reason = expiry.expiresAt <= now ? "해제 시각 지남" : "자동 해제 감시 중단"
        return "남아 있던 갱도 문을 안전하게 열었어요 · \(reason)"
    }

    var selectionSummary: String {
        "앱 \(selection.applicationTokens.count) · 카테고리 \(selection.categoryTokens.count)"
    }

    private var probeActivities: [DeviceActivityName] {
        center.activities.filter {
            $0.rawValue == ProbeConstants.activityName
                || $0.rawValue.hasPrefix("\(ProbeConstants.activityName).")
        }
    }

    private func stopAllProbeMonitoring() {
        let activities = probeActivities
        guard !activities.isEmpty else { return }
        center.stopMonitoring(activities)
    }

    private func scheduleMonitorBoundary(
        activity: DeviceActivityName,
        startsAt: Date,
        expiresAt: Date
    ) throws {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: startsAt),
            intervalEnd: calendar.dateComponents(components, from: expiresAt),
            repeats: false
        )
        try center.startMonitoring(
            activity,
            during: schedule
        )
    }

    private static func isAuthorized(_ status: AuthorizationStatus) -> Bool {
        if status == .approved {
            return true
        }
        if #available(iOS 26.4, *), status == .approvedWithDataAccess {
            return true
        }
        return false
    }

}
