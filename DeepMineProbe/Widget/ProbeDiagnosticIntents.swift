import AppIntents
import Foundation

struct RestartProbeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "60초 시험 채굴 다시 시작"
    static let supportedModes: IntentModes = [.background]

    func perform() async throws -> some IntentResult {
        let activityID = try await LiveActivityLifecycle.restart()
        ProbeDiagnostics.record(
            message: "진단 활동 재시작 완료 · id \(activityID)",
            source: "LiveActivityIntent",
            level: .success
        )
        return .result()
    }
}

struct WriteProbeRecordIntent: AppIntent {
    static let title: LocalizedStringResource = "보급 기록 남기기"
    static let supportedModes: IntentModes = [.background]

    func perform() async throws -> some IntentResult {
        let id = try await MainActor.run {
            try ProbeModelContainer.insert(source: "widget-intent")
        }
        ProbeDiagnostics.record(
            message: "SwiftData 저장 완료 · id \(id.uuidString)",
            source: "WidgetIntent",
            level: .success
        )
        return .result()
    }
}
