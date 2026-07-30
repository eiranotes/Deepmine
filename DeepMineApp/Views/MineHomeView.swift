import DeepMineCore
import SwiftUI

struct MineHomeView: View {
    let player: PlayerState
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
                mineControlScene
                equipmentSummary
                startButton
                ProgressNavigationPanel(context: progressContext)
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

    private var mineControlScene: some View {
        DeepMineRivetedPanel {
            VStack(spacing: 17) {
                mineScene
                Divider().overlay(DeepMinePalette.limestone.color.opacity(0.22))
                todayProgress
                planSelector
                durationSelector
                nextPromise
            }
        }
    }
}
