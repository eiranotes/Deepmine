import AppIntents
import Foundation

struct RestartProbeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "60초 시험 채굴 다시 시작"
    static let supportedModes: IntentModes = [.background]

    func perform() async throws -> some IntentResult {
        ProbeDiagnostics.record(
            message: "기존 LA end → 새 LA request 시작",
            source: "LiveActivityIntent",
            level: .info
        )
        do {
            let activityID = try await LiveActivityLifecycle.restart()
            ProbeDiagnostics.record(
                message: "재시작 완료 · id \(activityID)",
                source: "LiveActivityIntent",
                level: .success
            )
            return .result()
        } catch {
            ProbeDiagnostics.record(error: error, source: "LiveActivityIntent")
            throw error
        }
    }
}

struct WriteProbeRecordIntent: AppIntent {
    static let title: LocalizedStringResource = "보급 기록 남기기"
    static let supportedModes: IntentModes = [.background]

    func perform() async throws -> some IntentResult {
        do {
            let id = try await MainActor.run {
                try ProbeModelContainer.insert(source: "widget-intent")
            }
            ProbeDiagnostics.record(
                message: "SwiftData 저장 완료 · id \(id.uuidString)",
                source: "WidgetIntent",
                level: .success
            )
            return .result()
        } catch {
            ProbeDiagnostics.record(error: error, source: "WidgetIntent")
            throw error
        }
    }
}
