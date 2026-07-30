import DeepMineCore
import SwiftUI

enum ReturnReportTimeline {
    static let rewardRevealMilliseconds = 900
    static let nextRevealMilliseconds = 1_900
}

@MainActor
struct ReturnReportView: View {
    let presentation: ReturnReportPresentation
    let feedback: GameFeedback
    let onFinish: () -> Void
    let onPrepareNext: (ReturnUpgradeRecommendation?) -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var beat = 0
    @State var countedOre: Double = 0

    var body: some View {
        ZStack {
            DeepMinePalette.coal.color.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    confirmation
                    if beat >= 1 { rewardReveal }
                    if beat >= 2 { nextPromise }
                }
                .padding(17)
            }
        }
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.gameReturnReport))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task(id: presentation.report.completionID) { await reveal() }
        .accessibilityIdentifier("return-report")
    }

    var confirmation: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    // The outcome sprites already shipped but nothing drew them, so a
                    // collapse looked almost identical to a clean return.
                    Image(outcomeSpriteName)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DeepMineStrings.text(.returnConfirmationEyebrow))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DeepMinePalette.brass.color)
                            .accessibilityIdentifier("return-beat-confirmation")
                        Text(DeepMineStrings.text(outcomeKey))
                            .font(.title3.weight(.heavy))
                            .accessibilityIdentifier("return-outcome-\(outcomeIdentifier)")
                    }
                    Spacer()
                    DeepMineStatusMarker(status: gradeStatus, titleKey: gradeBadgeKey)
                }
                Label(
                    "\(presentation.report.focusedMinutes) \(DeepMineStrings.text(.gameMinutes))",
                    systemImage: "clock.badge.checkmark"
                )
                .font(.headline.monospacedDigit())
                Text(DeepMineStrings.text(gradeKey))
                    .font(.subheadline)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.74))
                    .accessibilityIdentifier("return-grade-\(presentation.report.verificationGrade.rawValue)")
            }
        }
    }

    var rewardReveal: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 13) {
                Text(DeepMineStrings.text(.returnRewardTitle))
                    .font(.headline)
                    .accessibilityIdentifier("return-beat-reward")
                // The one moment the screen is allowed to celebrate: the haul is the
                // largest thing on it, in brass.
                DeepMineCountingNumber(
                    value: countedOre,
                    prefix: "+",
                    font: .system(size: 46, weight: .heavy, design: .rounded)
                )
                .foregroundStyle(DeepMinePalette.brass.color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .countingUp(
                    to: presentation.report.oreEarned,
                    reduceMotion: reduceMotion,
                    into: $countedOre
                )
                .accessibilityLabel(
                    "\(DeepMineStrings.text(.gameOre)) +\(DeepMineNumberFormatter.string(presentation.report.oreEarned))"
                )
                .accessibilityIdentifier("return-ore")
                progressLines
                Divider().overlay(DeepMinePalette.limestone.color.opacity(0.22))
                if let vein = presentation.report.vein {
                    Label(
                        DeepMineStrings.text(veinTitleKey(vein)),
                        systemImage: veinSymbol(vein)
                    )
                    .font(.headline)
                    .accessibilityIdentifier("return-vein-\(vein.rawValue)")
                    Text(veinEffectText(vein))
                        .font(.subheadline)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                        .accessibilityIdentifier("return-vein-effect")
                } else {
                    Label(
                        DeepMineStrings.text(.returnNoVeinTitle),
                        systemImage: "mountain.2"
                    )
                    .font(.headline)
                    Text(DeepMineStrings.text(.returnNoVeinBody))
                        .font(.subheadline)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                    .accessibilityIdentifier("return-no-vein")
                }
            }
        }
        .revealTransition(reduceMotion: reduceMotion)
    }
}
