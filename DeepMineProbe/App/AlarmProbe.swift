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
            alert = .init(title: "DeepMine 프로브 완료")
        } else {
            let stopButton = AlarmButton(
                text: "중지",
                textColor: .white,
                systemImageName: "stop.fill"
            )
            alert = .init(title: "DeepMine 프로브 완료", stopButton: stopButton)
        }

        let presentation = AlarmPresentation(
            alert: alert,
            countdown: .init(title: "DeepMine 60초 프로브")
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: ProbeAlarmMetadata(source: "phase-0"),
            tintColor: ProbePalette.brass
        )
        let configuration: AlarmManager.AlarmConfiguration<ProbeAlarmMetadata> = .timer(
            duration: ProbeConstants.probeDuration,
            attributes: attributes
        )
        return try await manager.schedule(id: UUID(), configuration: configuration)
    }
}
