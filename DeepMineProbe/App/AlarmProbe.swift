import AlarmKit
import Foundation
import SwiftUI

struct ProbeAlarmMetadata: AlarmMetadata {
    let source: String
}

enum AlarmProbeError: LocalizedError {
    case authorizationDenied

    var errorDescription: String? {
        "AlarmKit authorization was denied."
    }
}

enum AlarmProbe {
    static func schedule60SecondAlarm() async throws -> Alarm {
        try await scheduleSessionAlarm(
            id: UUID(),
            duration: ProbeConstants.probeDuration,
            title: "DeepMine 프로브 완료",
            countdownTitle: "DeepMine 60초 프로브",
            source: "phase-0"
        )
    }

    static func scheduleSessionAlarm(
        id: UUID,
        duration: TimeInterval,
        title: String = "채굴 완료",
        countdownTitle: String = "DeepMine 집중 채굴",
        source: String = "game-session"
    ) async throws -> Alarm {
        let manager = AlarmManager.shared
        let authorization: AlarmManager.AuthorizationState

        switch manager.authorizationState {
        case .notDetermined:
            authorization = try await manager.requestAuthorization()
        case let current:
            authorization = current
        }

        guard authorization == .authorized else {
            throw AlarmProbeError.authorizationDenied
        }

        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = .init(title: LocalizedStringResource(stringLiteral: title))
        } else {
            let stopButton = AlarmButton(
                text: "중지",
                textColor: .white,
                systemImageName: "stop.fill"
            )
            alert = .init(
                title: LocalizedStringResource(stringLiteral: title),
                stopButton: stopButton
            )
        }

        let presentation = AlarmPresentation(
            alert: alert,
            countdown: .init(title: LocalizedStringResource(stringLiteral: countdownTitle))
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: ProbeAlarmMetadata(source: source),
            tintColor: ProbePalette.brass
        )
        let configuration: AlarmManager.AlarmConfiguration<ProbeAlarmMetadata> = .timer(
            duration: duration,
            attributes: attributes
        )
        return try await manager.schedule(id: id, configuration: configuration)
    }

    static func cancelSessionAlarm(id: UUID) throws {
        try AlarmManager.shared.cancel(id: id)
    }
}
