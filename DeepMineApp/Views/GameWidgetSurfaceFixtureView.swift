import AppIntents
import SwiftUI

struct GameWidgetSurfaceFixtureView: View {
    let stateName: String
    let surfaceName: String
    @Environment(\.locale) private var locale

    private var stateID: String {
        stateName.replacingOccurrences(of: "widget-", with: "")
    }

    private var result: GameSurfaceSnapshotReadResult {
        GameWidgetSnapshotFixtures.result(named: stateID)
    }

    var body: some View {
        ZStack {
            ProbePalette.coal.ignoresSafeArea()
            homeFixture
        }
        .preferredColorScheme(.dark)
    }

    private var homeFixture: some View {
        let family: GameHomeWidgetFamily = surfaceName == "medium" ? .medium : .small
        return GameHomeWidgetContent(result: result, family: family, date: Date())
            .padding(14)
            .frame(width: family == .medium ? 360 : 170, height: 170)
            .background(ProbePalette.shale, in: RoundedRectangle(cornerRadius: 18))
    }

}
