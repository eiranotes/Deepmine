import SwiftUI
import WidgetKit

@main
struct DeepMineWidgetBundle: WidgetBundle {
    var body: some Widget {
        DeepMineLiveActivityWidget()
        DeepMineAlarmLiveActivityWidget()
        DeepMineHomeWidget()
    }
}
