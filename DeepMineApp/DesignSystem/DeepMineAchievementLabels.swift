import DeepMineCore
import Foundation

/// Player-facing wording for the catalog. Titles are built from the metric and threshold
/// rather than stored per entry, so adding an achievement needs no new string.
enum DeepMineAchievementLabels {
    static func familyKey(_ family: AchievementFamily) -> DeepMineStringKey {
        switch family {
        case .firstSteps: .achievementFamilyFirstSteps
        case .accumulation: .achievementFamilyAccumulation
        case .depth: .achievementFamilyDepth
        case .discipline: .achievementFamilyDiscipline
        case .codex: .achievementFamilyCodex
        case .craft: .achievementFamilyCraft
        case .sealed: .achievementFamilySealed
        }
    }

    static func title(for definition: AchievementDefinition) -> String {
        let key: DeepMineStringKey = switch definition.metric {
        case .completedSessions: .achievementMetricSessions
        case .lifetimeFocusMinutes: .achievementMetricFocusHours
        case .depthMeters: .achievementMetricDepth
        case .streakDays: .achievementMetricStreak
        case .goalDaysEarned: .achievementMetricGoalDays
        case .distinctVeinKinds: .achievementMetricVeinKinds
        case .veinDiscoveries: .achievementMetricVeinFinds
        case .drillLevel: .achievementMetricDrill
        case .lowestEquipmentLevel: .achievementMetricAllEquipment
        case .sealedCompletions: .achievementMetricSealed
        case .prestigeCount: .achievementMetricPrestige
        case .deepCompletions: .achievementMetricDeep
        case .surveyCompletions: .achievementMetricSurvey
        }
        return String(format: DeepMineStrings.text(key), displayThreshold(definition))
    }

    static func progressText(_ entry: AchievementProgress) -> String {
        let scale = displayScale(entry.definition.metric)
        let current = entry.current / scale
        let target = entry.definition.threshold / scale
        return "\(current) / \(target)"
    }

    static func rewardText(_ reward: AchievementReward) -> String {
        switch reward {
        case let .crystals(quantity):
            return "\(DeepMineStrings.text(.gameCrystals)) +\(quantity)"
        case .decoration:
            return DeepMineStrings.text(.achievementRewardDecoration)
        case .theme:
            return DeepMineStrings.text(.achievementRewardTheme)
        case .badge:
            return DeepMineStrings.text(.achievementRewardBadge)
        }
    }

    /// Focus is stored in minutes but read in hours.
    private static func displayScale(_ metric: AchievementMetric) -> Int {
        metric == .lifetimeFocusMinutes ? 60 : 1
    }

    private static func displayThreshold(_ definition: AchievementDefinition) -> Int {
        definition.threshold / displayScale(definition.metric)
    }
}
