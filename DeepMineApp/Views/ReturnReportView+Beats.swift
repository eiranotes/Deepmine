import DeepMineCore
import SwiftUI

@MainActor
extension ReturnReportView {
    var progressLines: some View {
        VStack(alignment: .leading, spacing: 7) {
            progressRow(
                .gameDepth,
                detail: "\(presentation.report.depthMeters)m",
                symbol: "arrow.down.to.line.compact",
                identifier: "return-current-depth"
            )
            if presentation.report.depthGainedMeters > 0 {
                progressRow(
                    .returnDepthGain,
                    detail: "+\(presentation.report.depthGainedMeters)m",
                    symbol: "hammer.fill",
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

    func progressRow(
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

    var nextGoalPanel: some View {
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
    var nextRegionLine: some View {
        if let next = presentation.nextGoal.nextRegion {
            Label(
                "\(presentation.nextGoal.remainingDepthMeters)m · \(regionTitle(next))",
                systemImage: "arrow.down.to.line.compact"
            )
            .font(.subheadline.weight(.semibold))
            Text(DeepMineStrings.text(.returnRegionProgress))
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

    func recommendationLine(_ value: ReturnUpgradeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(
                "\(equipmentTitle(value.equipment)) · Lv.\(value.currentLevel) → \(value.nextLevel)",
                systemImage: equipmentSymbol(value.equipment)
            )
            .font(.subheadline.weight(.semibold))
            Text("\(DeepMineStrings.text(.returnRecommendationCost)) \(DeepMineNumberFormatter.string(big: value.cost)) · \(DeepMineStrings.text(.returnRecommendationOwned)) \(DeepMineNumberFormatter.string(big: value.availableOre))")
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

    func reveal() async {
        beat = 0
        try? await Task.sleep(for: .milliseconds(ReturnReportTimeline.rewardRevealMilliseconds))
        guard !Task.isCancelled else { return }
        setBeat(1)
        let played = feedback.playRewardOnce(
            completionID: presentation.report.completionID,
            grade: presentation.report.verificationGrade
        )
        if played, presentation.report.vein != nil {
            try? await Task.sleep(for: .milliseconds(260))
            guard !Task.isCancelled else { return }
            feedback.play(.veinFound)
        }
        try? await Task.sleep(for: .milliseconds(
            ReturnReportTimeline.nextRevealMilliseconds
                - ReturnReportTimeline.rewardRevealMilliseconds
        ))
        guard !Task.isCancelled else { return }
        setBeat(2)
        if played, !presentation.report.earnedAchievementIDs.isEmpty {
            feedback.play(.achievementEarned)
        }
    }

    func setBeat(_ value: Int) {
        if reduceMotion {
            beat = value
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.92)) { beat = value }
        }
    }
}

extension View {
    func revealTransition(reduceMotion: Bool) -> some View {
        transition(reduceMotion ? .opacity : .offset(y: 8).combined(with: .opacity))
    }
}
