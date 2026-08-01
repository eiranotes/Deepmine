import DeepMineCore
import SwiftUI

struct MineHomeView: View {
    let player: PlayerState
    /// The rock lives at the top of this screen rather than on one of its own. In an
    /// idle clicker the tap target and the progression panels are the same surface —
    /// splitting them would put every route one navigation step away from the thing the
    /// player is actually doing.
    var mineFace: AnyView?
    let recommendation: UpgradeRecommendation?
    /// Expected ore for the currently selected plan, used only to turn an ore shortfall
    /// into an estimated number of expeditions. Nil when it cannot be computed.
    let projectedOrePerSession: Double?
    let onSelectPlan: (MinePlan) -> Void
    let onSelectDuration: (SessionLength) -> Void
    let onStart: () -> Void
    let onUpgrade: (EquipmentKind) -> Void
    let onOpenSettings: () -> Void
    let progressContext: ProgressNavigationContext

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                masthead
                // The shaft is the game, so it sits directly under the ore counter and
                // above everything else. What used to lead this screen — a plan, a
                // duration and a promise to focus — is one optional route among the rest
                // now that the mine runs without it (D-047).
                if let mineFace {
                    mineFace
                        .accessibilityIdentifier("mine-home-rock")
                }
                equipmentSummary
                DeepMineRivetedPanel {
                    VStack(spacing: 15) {
                        nextPromise
                        mineScene
                    }
                }
                ProgressNavigationPanel(context: progressContext)
                focusAmplifier
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationMine))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("mine-home-screen")
    }

    private var masthead: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(DeepMineStrings.text(.homeMineScene))
                    .font(.title2.weight(.heavy))
                    .accessibilityIdentifier("mine-home")
                streakLine
            }
            Spacer()
            Label(
                DeepMineNumberFormatter.string(player.resources.ore),
                systemImage: "shippingbox.fill"
            )
            .font(.headline.monospacedDigit())
            .foregroundStyle(DeepMinePalette.brass.color)
            .accessibilityLabel(
                "\(DeepMineStrings.text(.gameOre)) \(DeepMineNumberFormatter.string(player.resources.ore))"
            )
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(DeepMinePalette.limestone.color)
            .accessibilityLabel(DeepMineStrings.text(.navigationSettings))
            .accessibilityIdentifier("mine-home-settings")
        }
    }

    /// Focus, as it stands after the pivot: an optional multiplier with its own panel,
    /// not the thing the screen is built around. Collapsed to a single control until the
    /// player opens it, so a mine that never focuses never has to look at a timer.
    private var focusAmplifier: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .foregroundStyle(DeepMinePalette.brass.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DeepMineStrings.text(.homeFocusAmplifierTitle))
                            .font(.subheadline.weight(.bold))
                        Text(DeepMineStrings.text(.homeFocusAmplifierDetail))
                            .font(.caption2)
                            .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("mine-home-focus-amplifier")
                todayProgress
                planSelector
                durationSelector
                startButton
            }
        }
    }

}
