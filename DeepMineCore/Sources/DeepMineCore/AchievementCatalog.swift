import Foundation

/// The shipped achievement set.
///
/// Every entry names something the player already did. There are no deadlines, no
/// refresh cycles and no penalties for not reaching one, which is what separates these
/// from the quests Spec §16 excludes (D-029). Conditions that would reward overuse —
/// sessions per day, minutes between sessions, finishing before midnight — are
/// deliberately absent.
public enum AchievementCatalog {
    public static let all: [AchievementDefinition] = firstSteps
        + accumulation
        + depth
        + discipline
        + codex
        + craft
        + sealedMining

    static let firstSteps: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first.return", family: .firstSteps, metric: .completedSessions,
            threshold: 1, reward: .crystals(1)
        ),
        AchievementDefinition(
            id: "first.deep", family: .firstSteps, metric: .deepCompletions,
            threshold: 1, reward: .crystals(2)
        ),
        AchievementDefinition(
            id: "first.survey", family: .firstSteps, metric: .surveyCompletions,
            threshold: 1, reward: .crystals(2)
        ),
        AchievementDefinition(
            id: "first.prestige", family: .firstSteps, metric: .prestigeCount,
            threshold: 1, reward: .decoration(.marker)
        )
    ]

    static let accumulation: [AchievementDefinition] = [
        AchievementDefinition(
            id: "focus.10h", family: .accumulation, metric: .lifetimeFocusMinutes,
            threshold: 600, reward: .crystals(2)
        ),
        AchievementDefinition(
            id: "focus.50h", family: .accumulation, metric: .lifetimeFocusMinutes,
            threshold: 3_000, reward: .crystals(4)
        ),
        AchievementDefinition(
            id: "focus.100h", family: .accumulation, metric: .lifetimeFocusMinutes,
            threshold: 6_000, reward: .decoration(.rail)
        ),
        AchievementDefinition(
            id: "focus.250h", family: .accumulation, metric: .lifetimeFocusMinutes,
            threshold: 15_000, reward: .crystals(8)
        ),
        AchievementDefinition(
            id: "focus.500h", family: .accumulation, metric: .lifetimeFocusMinutes,
            threshold: 30_000, reward: .badge
        ),
        AchievementDefinition(
            id: "sessions.25", family: .accumulation, metric: .completedSessions,
            threshold: 25, reward: .crystals(2)
        ),
        AchievementDefinition(
            id: "sessions.100", family: .accumulation, metric: .completedSessions,
            threshold: 100, reward: .crystals(4)
        ),
        AchievementDefinition(
            id: "sessions.500", family: .accumulation, metric: .completedSessions,
            threshold: 500, reward: .badge
        )
    ]

    static let depth: [AchievementDefinition] = [
        AchievementDefinition(
            id: "depth.crystal", family: .depth, metric: .depthMeters,
            threshold: Balance.crystalRegionDepth, reward: .crystals(2)
        ),
        AchievementDefinition(
            id: "depth.ruins", family: .depth, metric: .depthMeters,
            threshold: Balance.ruinsRegionDepth, reward: .crystals(4)
        ),
        AchievementDefinition(
            id: "depth.abyss", family: .depth, metric: .depthMeters,
            threshold: Balance.abyssRegionDepth, reward: .decoration(.lamp)
        ),
        AchievementDefinition(
            id: "depth.5000", family: .depth, metric: .depthMeters,
            threshold: 5_000, reward: .crystals(8)
        ),
        AchievementDefinition(
            id: "depth.20000", family: .depth, metric: .depthMeters,
            threshold: 20_000, reward: .badge
        )
    ]

    static let discipline: [AchievementDefinition] = [
        AchievementDefinition(
            id: "streak.3", family: .discipline, metric: .streakDays,
            threshold: Balance.streakDayThree, reward: .crystals(1)
        ),
        AchievementDefinition(
            id: "streak.7", family: .discipline, metric: .streakDays,
            threshold: Balance.streakDaySeven, reward: .crystals(3)
        ),
        AchievementDefinition(
            id: "streak.14", family: .discipline, metric: .streakDays,
            threshold: Balance.streakDayFourteen, reward: .decoration(.cart)
        ),
        AchievementDefinition(
            id: "streak.30", family: .discipline, metric: .streakDays,
            threshold: Balance.streakDayThirty, reward: .badge
        ),
        AchievementDefinition(
            id: "goal.30days", family: .discipline, metric: .goalDaysEarned,
            threshold: 30, reward: .crystals(4)
        ),
        AchievementDefinition(
            id: "goal.100days", family: .discipline, metric: .goalDaysEarned,
            threshold: 100, reward: .badge
        )
    ]

    static let codex: [AchievementDefinition] = [
        AchievementDefinition(
            id: "vein.first", family: .codex, metric: .veinDiscoveries,
            threshold: 1, reward: .crystals(1)
        ),
        AchievementDefinition(
            id: "vein.all5", family: .codex, metric: .distinctVeinKinds,
            threshold: VeinKind.allCases.count, reward: .theme(.crystal)
        ),
        AchievementDefinition(
            id: "vein.25", family: .codex, metric: .veinDiscoveries,
            threshold: 25, reward: .crystals(4)
        ),
        AchievementDefinition(
            id: "vein.100", family: .codex, metric: .veinDiscoveries,
            threshold: 100, reward: .badge
        )
    ]

    static let craft: [AchievementDefinition] = [
        AchievementDefinition(
            id: "drill.10", family: .craft, metric: .drillLevel,
            threshold: 10, reward: .crystals(2)
        ),
        AchievementDefinition(
            id: "drill.20", family: .craft, metric: .drillLevel,
            threshold: 20, reward: .crystals(4)
        ),
        AchievementDefinition(
            id: "drill.40", family: .craft, metric: .drillLevel,
            threshold: 40, reward: .crystals(8)
        ),
        AchievementDefinition(
            id: "drill.60", family: .craft, metric: .drillLevel,
            threshold: Balance.maximumEquipmentLevel, reward: .badge
        ),
        AchievementDefinition(
            id: "crew.balanced20", family: .craft, metric: .lowestEquipmentLevel,
            threshold: 20, reward: .theme(.ruins)
        )
    ]

    static let sealedMining: [AchievementDefinition] = [
        AchievementDefinition(
            id: "sealed.25", family: .sealed, metric: .sealedCompletions,
            threshold: 25, reward: .crystals(2)
        ),
        AchievementDefinition(
            id: "sealed.100", family: .sealed, metric: .sealedCompletions,
            threshold: 100, reward: .crystals(6)
        ),
        AchievementDefinition(
            id: "sealed.300", family: .sealed, metric: .sealedCompletions,
            threshold: 300, reward: .badge
        )
    ]
}
