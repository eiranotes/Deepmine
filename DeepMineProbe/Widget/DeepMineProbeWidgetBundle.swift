import SwiftUI
import WidgetKit

@main
struct DeepMineProbeWidgetBundle: WidgetBundle {
    var body: some Widget {
        DeepMineLiveActivityWidget()
        DeepMineAlarmLiveActivityWidget()
        DeepMineHomeWidget()
    }
}
