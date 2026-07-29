import ActivityKit
import Combine
import Foundation

@MainActor
final class ProbeViewModel: ObservableObject {
    @Published private(set) var entries: [ProbeLogEntry] = []
    @Published private(set) var activeActivityCount = 0
    @Published private(set) var isBusy = false
    @Published var transientMessage: String?

    private var clockAnchor: ClockAnchor?
    private let clockSource = SystemProbeClockSource()

    func refresh() {
        activeActivityCount = Activity<DeepMineActivityAttributes>.activities.count
        do {
            entries = try ProbeSharedStores.logStore().read().sorted { $0.timestamp > $1.timestamp }
        } catch {
            ProbeDiagnostics.logPrivate(error: error, source: "ProbeLogRead")
            transientMessage = ProbeDiagnostics.safeSummary(for: error)
        }
    }

    func startLiveActivity() async {
        await run(source: "LiveActivity") {
            let activityID = try await LiveActivityLifecycle.start()
            return "잠금화면 표지를 60초 동안 켰어요 · 완료 전환 대기 · id \(activityID)"
        }
    }

    func restartLiveActivity() async {
        await run(source: "LiveActivity") {
            let activityID = try await LiveActivityLifecycle.restart()
            return "기존 표지를 닫고 새 표지를 켰어요 · id \(activityID)"
        }
    }

    func scheduleAlarm() async {
        await run(source: "AlarmKit") {
            let alarm = try await AlarmProbe.schedule60SecondAlarm()
            return "종료 종을 60초 뒤로 예약했어요 · id \(alarm.id.uuidString) · 상태 \(String(describing: alarm.state))"
        }
    }

    func requestScreenTimeAuthorization(_ screenTime: ScreenTimeProbe) async {
        await run(source: "FamilyControls") {
            let status = try await screenTime.requestAuthorization()
            return "방해 앱 차단 권한 결과 · \(status.description)"
        }
    }

    func persistSelection(_ screenTime: ScreenTimeProbe) {
        do {
            try screenTime.persistSelection()
            record(
                source: "FamilyControls",
                level: .success,
                message: "선택 저장 · \(screenTime.selectionSummary)"
            )
        } catch {
            recordError(source: "FamilyControls", error: error)
        }
    }

    func applyShields(_ screenTime: ScreenTimeProbe) {
        do {
            let result = try screenTime.applyShields()
            record(
                source: "ManagedSettings",
                level: .success,
                message: String(
                    format: "갱도 문 잠금 요청 %.3f초 · %@ · 자동 해제 %@",
                    result.elapsed,
                    screenTime.selectionSummary,
                    result.expiresAt.formatted(date: .omitted, time: .standard)
                )
            )
        } catch {
            recordError(source: "ManagedSettings", error: error)
        }
    }

    func clearShields(_ screenTime: ScreenTimeProbe) {
        do {
            let elapsed = try screenTime.clearShields()
            record(
                source: "ManagedSettings",
                level: .success,
                message: String(format: "갱도 문 비상 해제 %.3f초", elapsed)
            )
        } catch {
            recordError(source: "ManagedSettings", error: error)
        }
    }

    func recoverShieldIfNeeded(_ screenTime: ScreenTimeProbe) {
        do {
            if let message = try screenTime.recoverExpiredShieldIfNeeded() {
                record(source: "ManagedSettings", level: .warning, message: message)
            }
        } catch {
            recordError(source: "ShieldRecovery", error: error)
        }
    }

    func startClockObservation() {
        clockAnchor = ClockProbe.start(source: clockSource)
        record(source: "Clock", level: .info, message: "두 모래시계의 시작 시각을 함께 남겼어요")
    }

    func finishClockObservation() {
        guard let clockAnchor else {
            record(source: "Clock", level: .warning, message: "먼저 시간 관측을 시작해야 합니다.")
            return
        }
        let observation = ClockProbe.finish(anchor: clockAnchor, source: clockSource)
        self.clockAnchor = nil

        if observation.assessment == .rebooted {
            record(
                source: "Clock",
                level: .warning,
                message: String(
                    format: "기기 재시작 감지 · 벽시계 %.3f초 · 기록은 그대로 유지",
                    observation.wallElapsed
                )
            )
            return
        }

        record(
            source: "Clock",
            level: observation.assessment == .tampered ? .warning : .success,
            message: String(
                format: "%@ · 일반 시계 %.3f초 · 연속 시계 %.3f초 · 차이 %+.3f초",
                observation.assessment.rawValue,
                observation.wallElapsed,
                observation.continuousElapsed ?? 0,
                observation.drift ?? 0
            )
        )
    }

    func refreshSharedWrites() {
        do {
            let records = try ProbeModelContainer.acknowledgeAll()
            guard !records.isEmpty else {
                refresh()
                return
            }
            for sharedWrite in records {
                record(
                    source: "SwiftData",
                    level: .success,
                    message: "홈 화면의 보급 기록이 도착했어요 · \(sharedWrite.id.uuidString)"
                )
            }
        } catch {
            recordError(source: "SwiftData", error: error)
        }
    }

    private func run(
        source: String,
        operation: () async throws -> String
    ) async {
        isBusy = true
        defer {
            isBusy = false
            refresh()
        }
        do {
            record(source: source, level: .info, message: "시험을 시작했어요")
            let message = try await operation()
            record(source: source, level: .success, message: message)
        } catch {
            recordError(source: source, error: error)
        }
    }

    private func recordError(source: String, error: Error) {
        ProbeDiagnostics.logPrivate(error: error, source: source)
        transientMessage = "\(sourceName(source)) 준비 실패: \(ProbeDiagnostics.safeSummary(for: error))"
        record(
            source: source,
            level: .error,
            message: ProbeDiagnostics.safeSummary(for: error)
        )
    }

    private func record(source: String, level: ProbeLogLevel, message: String) {
        let entry = ProbeLogEntry(source: source, level: level, message: message)
        do {
            try ProbeSharedStores.logStore().append(entry)
            refresh()
        } catch {
            if transientMessage == nil {
                ProbeDiagnostics.logPrivate(error: error, source: "ProbeLogWrite")
                transientMessage = "채굴 일지 기록 실패: \(ProbeDiagnostics.safeSummary(for: error))"
            }
            entries.insert(entry, at: 0)
        }
    }

    private func sourceName(_ source: String) -> String {
        switch source {
        case "LiveActivity", "LiveActivityIntent": "잠금화면 표지"
        case "AlarmKit": "종료 종"
        case "ManagedSettings", "FamilyControls", "ShieldRecovery": "갱도 문"
        case "Clock": "모래시계"
        case "SwiftData", "WidgetIntent": "보급 상자"
        default: "시스템"
        }
    }
}
