import DeepMineCore
import Foundation
import UserNotifications

enum SessionShieldOutcome: Equatable, Sendable {
    case sealed
    case open(reason: String)
}
enum SessionShieldIntegrity: String, Codable, Equatable, Sendable {
    case maintained
    case removed
    case unavailable
}
enum SessionAlarmDelivery: String, Codable, Equatable, Sendable {
    case alarmKit
    case localNotification
    case none
}
struct SessionSystemStartResult: Equatable, Sendable {
    let shield: SessionShieldOutcome
    let alarmDelivery: SessionAlarmDelivery
    let liveActivityID: String?
    let warnings: [String]
}
@MainActor
protocol SessionSystemCoordinating: AnyObject {
    func start(
        _ session: PersistedGameSession,
        player: PlayerState,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) async -> SessionSystemStartResult
    func finish(
        _ session: PersistedGameSession,
        completedSnapshot: GameSurfaceSnapshot?
    ) async -> [String]
    func publishWaiting(_ snapshot: GameSurfaceSnapshot) async -> Bool
    func recoverExpiredShield(at date: Date) async -> [String]
    func shieldIntegrity(for session: PersistedGameSession) -> SessionShieldIntegrity
    func forceRemoveShield(for session: PersistedGameSession) async -> Bool
}

struct AnyGameClock: DeepMineCore.ClockSource {
    private let wall: @Sendable () -> Date
    private let continuous: @Sendable () -> UInt64

    init(_ source: any DeepMineCore.ClockSource) {
        wall = source.wallNow
        continuous = source.continuousNanoseconds
    }

    func wallNow() -> Date { wall() }
    func continuousNanoseconds() -> UInt64 { continuous() }
}
struct SystemGameClock: DeepMineCore.ClockSource {
    func wallNow() -> Date { Date() }

    /// `CLOCK_MONOTONIC_RAW` keeps counting while the device sleeps, unlike
    /// `systemUptime`/`CLOCK_UPTIME_RAW`. A phone put face down for a 50 minute
    /// session is the normal case here, and an uptime clock would drift behind the
    /// wall clock far enough to read as tampering and downgrade an honest session.
    func continuousNanoseconds() -> UInt64 {
        clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
    }
}

@MainActor
final class SessionSystemCoordinator: SessionSystemCoordinating {
    private let screenTime: ScreenTimeProbe
    private let notificationCenter: UNUserNotificationCenter
    private let snapshotWriter: GameSurfaceSnapshotWriter?

    init(
        screenTime: ScreenTimeProbe = ScreenTimeProbe(),
        notificationCenter: UNUserNotificationCenter = .current(),
        snapshotWriter: GameSurfaceSnapshotWriter? = try? .shared()
    ) {
        self.screenTime = screenTime
        self.notificationCenter = notificationCenter
        self.snapshotWriter = snapshotWriter
    }

    func start(
        _ session: PersistedGameSession,
        player: PlayerState,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) async -> SessionSystemStartResult {
        var warnings: [String] = []
        let shield: SessionShieldOutcome
        do {
            _ = try screenTime.applyShields(
                sessionID: session.id,
                startsAt: session.startedAt,
                expiresAt: session.endsAt
            )
            shield = .sealed
        } catch {
            let reason = Self.summary(error)
            shield = .open(reason: reason)
            warnings.append(reason)
        }

        let activityID: String?
        do {
            let grade: VerificationGrade = shield == .sealed ? .sealed : .open
            let snapshot = try GameSurfaceSnapshotMapper.active(
                session: session,
                player: player,
                grade: grade,
                at: date,
                calendar: calendar,
                timeZone: timeZone
            )
            do {
                guard let snapshotWriter else {
                    throw GameSurfaceSnapshotStoreError.missingAppGroup(
                        ProbeConstants.appGroupIdentifier
                    )
                }
                try snapshotWriter.write(snapshot)
            } catch {
                warnings.append("공유 진행 정보를 저장하지 못했습니다. 앱을 열어 새로고침해 주세요.")
                ProbeDiagnostics.record(error: error, source: "GameSurfaceSnapshotStart")
            }
            activityID = try await LiveActivityLifecycle.startSession(
                id: session.id,
                startedAt: session.startedAt,
                endsAt: session.endsAt,
                snapshot: snapshot
            )
        } catch {
            activityID = nil
            warnings.append("실시간 진행 표시를 시작하지 못했지만 채굴은 계속됩니다.")
            ProbeDiagnostics.record(error: error, source: "GameLiveActivityStart")
        }

        let alarmDelivery: SessionAlarmDelivery
        do {
            try? AlarmProbe.cancelSessionAlarm(id: session.id)
            _ = try await AlarmProbe.scheduleSessionAlarm(
                id: session.id,
                duration: max(1, session.endsAt.timeIntervalSinceNow)
            )
            alarmDelivery = .alarmKit
        } catch {
            ProbeDiagnostics.record(error: error, source: "GameAlarmKitSchedule")
            do {
                try await scheduleLocalFallback(for: session)
                alarmDelivery = .localNotification
                warnings.append("시스템 알람 대신 일반 알림으로 완료를 알려드립니다.")
            } catch {
                alarmDelivery = .none
                warnings.append("완료 알림을 예약하지 못했습니다. 앱에서 종료 시각을 확인해 주세요.")
                ProbeDiagnostics.record(error: error, source: "GameNotificationFallback")
            }
        }
        return SessionSystemStartResult(
            shield: shield,
            alarmDelivery: alarmDelivery,
            liveActivityID: activityID,
            warnings: Array(warnings.prefix(8))
        )
    }

    func finish(
        _ session: PersistedGameSession,
        completedSnapshot: GameSurfaceSnapshot?
    ) async -> [String] {
        var warnings: [String] = []
        if let completedSnapshot {
            do {
                guard let snapshotWriter else {
                    throw GameSurfaceSnapshotStoreError.missingAppGroup(
                        ProbeConstants.appGroupIdentifier
                    )
                }
                try snapshotWriter.write(completedSnapshot)
            } catch {
                warnings.append("완료 정보를 공유 표면에 저장하지 못했습니다.")
                ProbeDiagnostics.record(error: error, source: "GameSurfaceSnapshotFinish")
            }
            do {
                try await LiveActivityLifecycle.completeSession(
                    id: session.id,
                    snapshot: completedSnapshot
                )
            } catch {
                warnings.append("실시간 완료 표시를 갱신하지 못했습니다.")
                ProbeDiagnostics.record(error: error, source: "GameLiveActivityFinish")
            }
        } else {
            await LiveActivityLifecycle.endSessionImmediately(id: session.id)
        }
        do {
            _ = try screenTime.clearShields(sessionID: session.id)
        } catch {
            warnings.append("차단 해제를 확인하지 못했습니다. 다음 실행에서 다시 복구합니다.")
            ProbeDiagnostics.record(error: error, source: "GameShieldFinish")
        }
        if session.alarmDelivery == .alarmKit {
            do {
                try AlarmProbe.cancelSessionAlarm(id: session.id)
            } catch {
                warnings.append("예약된 시스템 알람 해제를 확인하지 못했습니다.")
                ProbeDiagnostics.record(error: error, source: "GameAlarmFinish")
            }
        }
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: session)]
        )
        return warnings
    }

    func publishWaiting(_ snapshot: GameSurfaceSnapshot) async -> Bool {
        do {
            guard let snapshotWriter else {
                throw GameSurfaceSnapshotStoreError.missingAppGroup(
                    ProbeConstants.appGroupIdentifier
                )
            }
            try snapshotWriter.write(snapshot)
            return true
        } catch {
            ProbeDiagnostics.record(error: error, source: "GameSurfaceSnapshotWaiting")
            return false
        }
    }
    func recoverExpiredShield(at date: Date) async -> [String] {
        do {
            guard let message = try screenTime.recoverExpiredShieldIfNeeded(now: date) else {
                return []
            }
            return [message]
        } catch {
            ProbeDiagnostics.record(error: error, source: "GameShieldRecovery")
            return ["남아 있는 차단 상태를 확인하지 못했습니다."]
        }
    }
    func shieldIntegrity(for session: PersistedGameSession) -> SessionShieldIntegrity {
        screenTime.shieldIntegrity(sessionID: session.id)
    }

    func forceRemoveShield(for session: PersistedGameSession) async -> Bool {
        do {
            _ = try screenTime.clearShields(sessionID: session.id)
            return true
        } catch {
            ProbeDiagnostics.record(error: error, source: "GameShieldForcedRemoval")
            return false
        }
    }

    private func scheduleLocalFallback(for session: PersistedGameSession) async throws {
        let settings = await notificationCenter.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        }
        let refreshed = await notificationCenter.notificationSettings()
        guard refreshed.authorizationStatus == .authorized
                || refreshed.authorizationStatus == .provisional else {
            throw AlarmProbeError.authorizationDenied
        }
        let content = UNMutableNotificationContent()
        content.title = "채굴 완료"
        content.body = "DeepMine으로 돌아와 채굴 결과를 확인해 보세요."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, session.endsAt.timeIntervalSinceNow), repeats: false
        )
        try await notificationCenter.add(UNNotificationRequest(
            identifier: notificationIdentifier(for: session),
            content: content,
            trigger: trigger
        ))
    }

    private func notificationIdentifier(for session: PersistedGameSession) -> String {
        "deepmine.session.\(session.id.uuidString)"
    }

    private static func summary(_ error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription {
            return String(description.prefix(240))
        }
        return "집중 차단을 적용하지 못해 열린 채굴로 진행합니다."
    }
}
