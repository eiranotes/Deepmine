import SwiftUI
import WidgetKit

struct DeepMineControlValueProvider: ControlValueProvider {
    var previewValue: GameControlValue {
        GameControlValue(stateID: "waiting", phase: .waiting, canStart: true)
    }

    func currentValue() async throws -> GameControlValue {
        let result = try GameSurfaceSnapshotStore.shared().read()
        return GameControlValue.make(from: result)
    }
}

struct DeepMineControlWidget: ControlWidget {
    let kind = GamePassiveSurfaceKinds.safeControl

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind, provider: DeepMineControlValueProvider()) { value in
            ControlWidgetButton(action: OpenAndStartSafeMineIntent()) {
                GameControlSurfaceLabel(value: value)
            }
        }
        .displayName("control.safe.name")
        .description("control.safe.description")
    }
}
