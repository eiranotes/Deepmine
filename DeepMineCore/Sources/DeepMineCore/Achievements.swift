import Foundation

/// What an achievement can pay out. Deliberately excludes ore, multipliers, equipment
/// and shards: a reward that raises production would create a way to grow without
/// focusing, which is the one thing the product does not allow (D-028).
public enum AchievementReward: Codable, Equatable, Hashable, Sendable {
    case crystals(Int)
    case decoration(MineDecoration)
    case theme(MineTheme)
    case badge
}

public enum AchievementFamily: String, Codable, CaseIterable, Sendable {
    case firstSteps
    case accumulation
    case depth
    case discipline
    case codex
    case craft
    case sealed
}

/// The measurable quantity an achievement watches. Every case reads from state the game
/// already records, so achievements never need their own bookkeeping.
public enum AchievementMetric: String, Codable, CaseIterable, Sendable {
    case completedSessions
    case lifetimeFocusMinutes
    case depthMeters
    case streakDays
    case miningDays
    case distinctVeinKinds
    case veinDiscoveries
    case drillLevel
    case lowestEquipmentLevel
    case sealedCompletions
    case prestigeCount
    case deepCompletions
    case surveyCompletions
}

public struct AchievementDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let family: AchievementFamily
    public let metric: AchievementMetric
    public let threshold: Int
    public let reward: AchievementReward

    public init(
        id: String,
        family: AchievementFamily,
        metric: AchievementMetric,
        threshold: Int,
        reward: AchievementReward
    ) {
        self.id = id
        self.family = family
        self.metric = metric
        self.threshold = threshold
        self.reward = reward
    }
}

public struct AchievementProgress: Equatable, Sendable {
    public let definition: AchievementDefinition
    public let current: Int
    public let isEarned: Bool

    public var fraction: Double {
        guard definition.threshold > 0 else { return 1 }
        return min(1, Double(current) / Double(definition.threshold))
    }

    public var remaining: Int { max(0, definition.threshold - current) }

    public init(definition: AchievementDefinition, current: Int, isEarned: Bool) {
        self.definition = definition
        self.current = current
        self.isEarned = isEarned
    }
}

public struct AchievementGrant: Equatable, Sendable {
    public let definition: AchievementDefinition
    public let appliedReward: AchievementReward?

    public init(definition: AchievementDefinition, appliedReward: AchievementReward?) {
        self.definition = definition
        self.appliedReward = appliedReward
    }
}

public enum AchievementEngine {
    /// Snapshot of every measurable quantity, derived once so a full evaluation does not
    /// walk history 30 times.
    struct Measurements {
        var values: [AchievementMetric: Int] = [:]

        init(_ state: PlayerState) {
            let completed = state.history.filter(\.completed)
            values[.completedSessions] = state.completedSessionCount
            values[.lifetimeFocusMinutes] = Self.saturating(
                state.lifetimeFocusCredits * Balance.minutesPerFocusCredit
            )
            // Depth achievements mark the deepest point ever reached; a prestige is not
            // a reason to take a badge back.
            values[.depthMeters] = state.recordDepthMeters
            values[.streakDays] = state.streakDays
            values[.miningDays] = state.dailyRecords.count
            values[.distinctVeinKinds] = Set(state.history.compactMap(\.vein)).count
            values[.veinDiscoveries] = state.history.count { $0.vein != nil }
            values[.drillLevel] = state.equipment.drill
            values[.lowestEquipmentLevel] = min(
                state.equipment.drill,
                min(state.equipment.cart, state.equipment.lamp)
            )
            values[.sealedCompletions] = completed.count { $0.verificationGrade == .sealed }
            values[.prestigeCount] = state.prestigeIndex
            values[.deepCompletions] = completed.count { $0.plan == .deep }
            values[.surveyCompletions] = completed.count { $0.plan == .survey }
        }

        private static func saturating(_ value: Double) -> Int {
            guard value.isFinite, value > 0 else { return 0 }
            return value >= Double(Int.max) ? Int.max : Int(value)
        }
    }

    public static func progress(for state: PlayerState) -> [AchievementProgress] {
        let measurements = Measurements(state)
        return AchievementCatalog.all.map { definition in
            AchievementProgress(
                definition: definition,
                current: measurements.values[definition.metric] ?? 0,
                isEarned: state.earnedAchievementIDs.contains(definition.id)
            )
        }
    }

    /// Awards anything newly satisfied. Idempotent: an id already in
    /// `earnedAchievementIDs` is never paid twice, so replaying a session is safe.
    @discardableResult
    public static func evaluate(in state: inout PlayerState) -> [AchievementGrant] {
        let measurements = Measurements(state)
        var grants: [AchievementGrant] = []
        for definition in AchievementCatalog.all
        where !state.earnedAchievementIDs.contains(definition.id) {
            let current = measurements.values[definition.metric] ?? 0
            guard current >= definition.threshold else { continue }
            state.earnedAchievementIDs.insert(definition.id)
            grants.append(AchievementGrant(
                definition: definition,
                appliedReward: apply(definition.reward, to: &state)
            ))
        }
        return grants
    }

    /// Returns the reward that actually landed. A theme or decoration already owned pays
    /// nothing rather than silently converting to another currency.
    private static func apply(
        _ reward: AchievementReward,
        to state: inout PlayerState
    ) -> AchievementReward? {
        switch reward {
        case let .crystals(quantity):
            state.resources.crystals = saturatingAdd(state.resources.crystals, quantity)
            return reward
        case let .decoration(decoration):
            return state.unlockedDecorations.insert(decoration).inserted ? reward : nil
        case let .theme(theme):
            return state.unlockedThemes.insert(theme).inserted ? reward : nil
        case .badge:
            return reward
        }
    }

    private static func saturatingAdd(_ value: Int, _ addition: Int) -> Int {
        guard value >= 0 else { return addition }
        return value > Int.max - addition ? Int.max : value + addition
    }
}
