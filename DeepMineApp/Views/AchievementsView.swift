import DeepMineCore
import SwiftUI

/// The long-horizon surface. Unearned entries show their condition and current progress
/// on purpose: the home screen deliberately shows only the next promise, so this is
/// where a player can see that the mine keeps going for months.
@MainActor
struct AchievementsView: View {
    let player: PlayerState

    private var progress: [AchievementProgress] {
        AchievementEngine.progress(for: player)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                summaryPanel
                ForEach(AchievementFamily.allCases, id: \.self) { family in
                    let entries = progress.filter { $0.definition.family == family }
                    if !entries.isEmpty {
                        familyPanel(family, entries: entries)
                    }
                }
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationAchievements))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("achievements-screen")
    }

    private var summaryPanel: some View {
        let earned = progress.count(where: \.isEarned)
        return DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(DeepMineStrings.text(.achievementsEarnedTitle))
                        .font(.headline)
                    Spacer()
                    Text("\(earned) / \(progress.count)")
                        .font(.title3.monospacedDigit().weight(.heavy))
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .accessibilityIdentifier("achievements-count")
                }
                DeepMineProgressRail(
                    value: Double(earned),
                    total: Double(max(1, progress.count)),
                    accessibilityLabel: DeepMineStrings.text(.achievementsEarnedTitle)
                )
                Text(DeepMineStrings.text(.achievementsRewardNote))
                    .font(.caption)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func familyPanel(
        _ family: AchievementFamily,
        entries: [AchievementProgress]
    ) -> some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text(DeepMineStrings.text(DeepMineAchievementLabels.familyKey(family)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                // Nearest goal first so the next thing to chase is at the top.
                ForEach(sorted(entries), id: \.definition.id) { row($0) }
            }
        }
        .accessibilityIdentifier("achievements-family-\(family.rawValue)")
    }

    private func sorted(_ entries: [AchievementProgress]) -> [AchievementProgress] {
        entries.sorted { lhs, rhs in
            if lhs.isEarned != rhs.isEarned { return !lhs.isEarned }
            if lhs.isEarned { return lhs.definition.threshold < rhs.definition.threshold }
            return lhs.fraction > rhs.fraction
        }
    }

    private func row(_ entry: AchievementProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: entry.isEarned ? "checkmark.seal.fill" : "circle.dashed")
                    .font(.caption)
                    .foregroundStyle(
                        entry.isEarned
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.limestone.color.opacity(0.5)
                    )
                    .frame(width: 18)
                Text(DeepMineAchievementLabels.title(for: entry.definition))
                    .font(.subheadline.weight(entry.isEarned ? .bold : .regular))
                Spacer(minLength: 8)
                Text(DeepMineAchievementLabels.rewardText(entry.definition.reward))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.66))
            }
            if !entry.isEarned {
                DeepMineProgressRail(
                    value: Double(entry.current),
                    total: Double(entry.definition.threshold),
                    accessibilityLabel: DeepMineAchievementLabels.title(for: entry.definition)
                )
                Text(DeepMineAchievementLabels.progressText(entry))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.6))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(
            "achievement-\(entry.definition.id)-\(entry.isEarned ? "earned" : "pending")"
        )
    }
}
