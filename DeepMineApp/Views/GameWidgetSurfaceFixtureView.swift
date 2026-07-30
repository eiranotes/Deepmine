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
            if surfaceName == "control" {
                controlFixture
            } else {
                homeFixture
            }
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

    private var controlFixture: some View {
        let value = GameControlValue.make(from: result)
        return VStack(spacing: 0) {
            Button(intent: OpenAndStartSafeMineIntent()) {
                GameControlSurfaceLabel(value: value)
                    .foregroundStyle(ProbePalette.limestone)
                    .frame(minWidth: 132, minHeight: 64)
                    .background(ProbePalette.shale, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(value.title(locale: locale))
            .accessibilityIdentifier("control-action")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("control-fixture-\(value.stateID)")
    }
}
