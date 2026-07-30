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

    private var confirmation: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
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

    private var rewardReveal: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 13) {
                Text(DeepMineStrings.text(.returnRewardTitle))
                    .font(.headline)
                    .accessibilityIdentifier("return-beat-reward")
                // The one moment the screen is allowed to celebrate: the haul is the
                // largest thing on it, in brass.
                Text("+\(DeepMineNumberFormatter.string(presentation.report.oreEarned))")
                    .font(.system(size: 46, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    /// What the session moved, not just what it paid. Depth is the identity number and
    /// the streak is the reason to come back tomorrow, so both belong in the reveal.
    private var progressLines: some View {
        VStack(alignment: .leading, spacing: 7) {
            if presentation.report.depthGainedMeters > 0 {
                progressRow(
                    .returnDepthGain,
                    detail: "+\(presentation.report.depthGainedMeters)m",
                    symbol: "arrow.down.to.line.compact",
                    identifier: "return-depth-gain"
                )
            }
            progressRow(
                .returnTodayProgress,
                detail: "\(presentation.report.todayFocusedMinutes) / \(presentation.report.todayGoalMinutes) \(DeepMineStrings.text(.gameMinutes))",
                symbol: "target",
                identifier: "return-today"
            )
            progressRow(
                .returnStreakKept,
                detail: "\(presentation.report.streakDays)\(DeepMineStrings.text(.gameDays))",
                symbol: "flame.fill",
                identifier: "return-streak"
            )
            if presentation.report.streakEarnedToday {
                Text(DeepMineStrings.text(.returnStreakEarned))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("return-streak-earned")
            }
            if !presentation.report.earnedAchievementIDs.isEmpty {
                Label(
                    String(
                        format: DeepMineStrings.text(.returnAchievementsEarned),
                        presentation.report.earnedAchievementIDs.count
                    ),
                    systemImage: "rosette"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeepMinePalette.brass.color)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("return-achievements")
            }
        }
    }

    private func progressRow(
        _ key: DeepMineStringKey,
        detail: String,
        symbol: String,
        identifier: String
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.6))
                .frame(width: 18)
            Text(DeepMineStrings.text(key))
                .font(.subheadline)
            Spacer(minLength: 8)
            Text(detail)
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private var nextPromise: some View {
        VStack(alignment: .leading, spacing: 13) {
            DeepMineRivetedPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text(DeepMineStrings.text(.returnNextTitle))
                        .font(.headline)
                        .accessibilityIdentifier("return-beat-next")
                    nextRegionLine
                    if let recommendation = presentation.recommendation {
                        recommendationLine(recommendation)
                    } else {
                        Text(DeepMineStrings.text(.returnRecommendationMaximum))
                            .font(.subheadline)
                    }
                }
            }
            Button(action: onFinish) {
                DeepMineActionLabel(titleKey: .actionFinish, detailKey: nil, symbol: "checkmark")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            .accessibilityIdentifier("return-finish")
            Button { onPrepareNext(presentation.recommendation) } label: {
                DeepMineActionLabel(
                    titleKey: .actionNextExpedition,
                    detailKey: nil,
                    symbol: "wrench.and.screwdriver"
                )
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            .accessibilityIdentifier("return-prepare-next")
        }
        .revealTransition(reduceMotion: reduceMotion)
    }

    @ViewBuilder
    private var nextRegionLine: some View {
        if let next = presentation.nextPromise.nextRegion {
            Label(
                "\(presentation.nextPromise.remainingDepthMeters)m · \(regionTitle(next))",
                systemImage: "arrow.down.to.line.compact"
            )
            .font(.subheadline.weight(.semibold))
            Text(DeepMineStrings.text(.returnRegionPromise))
                .font(.caption)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
        } else {
            Label(
                DeepMineStrings.text(.returnDeepestRegion),
                systemImage: "checkmark.seal"
            )
            .font(.subheadline.weight(.semibold))
        }
    }

    private func recommendationLine(_ value: ReturnUpgradeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(
                "\(equipmentTitle(value.equipment)) · Lv.\(value.currentLevel) → \(value.nextLevel)",
                systemImage: equipmentSymbol(value.equipment)
            )
            .font(.subheadline.weight(.semibold))
            Text("\(DeepMineStrings.text(.returnRecommendationCost)) \(DeepMineNumberFormatter.string(value.cost)) · \(DeepMineStrings.text(.returnRecommendationOwned)) \(DeepMineNumberFormatter.string(value.availableOre))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
            Text(DeepMineStrings.text(
                value.isAffordable ? .returnRecommendationAffordable : .returnRecommendationUnaffordable
            ))
            .font(.caption.weight(.semibold))
            .foregroundStyle(value.isAffordable ? DeepMinePalette.limestone.color : DeepMinePalette.brass.color)
            .accessibilityIdentifier(
                value.isAffordable
                    ? "return-recommendation-affordable"
                    : "return-recommendation-unaffordable"
            )
        }
    }

    private func reveal() async {
        beat = 0
        try? await Task.sleep(for: .milliseconds(ReturnReportTimeline.rewardRevealMilliseconds))
        guard !Task.isCancelled else { return }
        setBeat(1)
        _ = feedback.playRewardOnce(
            completionID: presentation.report.completionID,
            grade: presentation.report.verificationGrade
        )
        try? await Task.sleep(for: .milliseconds(
            ReturnReportTimeline.nextRevealMilliseconds
                - ReturnReportTimeline.rewardRevealMilliseconds
        ))
        guard !Task.isCancelled else { return }
        setBeat(2)
    }

    private func setBeat(_ value: Int) {
        if reduceMotion {
            beat = value
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.92)) { beat = value }
        }
    }
}

private extension View {
    func revealTransition(reduceMotion: Bool) -> some View {
        transition(reduceMotion ? .opacity : .offset(y: 8).combined(with: .opacity))
    }
}
