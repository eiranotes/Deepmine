import Foundation

public struct PrestigeLossPreview: Codable, Equatable, Sendable {
    public let ore: Double
    public let runSegmentsBroken: Int
    public let equipment: EquipmentLevels
}

public struct PrestigeGainPreview: Codable, Equatable, Sendable {
    public let coreShards: Int
    /// Depth, crystals, themes, streak and the remembered rebuy discount all survive.
    public let keptDepthMeters: Int
    public let rebuyDiscount: Double
}

public struct PrestigePreview: Codable, Equatable, Sendable {
    public let losses: PrestigeLossPreview
    public let gains: PrestigeGainPreview
    public let currentRunSegments: Int
    public let targetRunSegments: Int
    public let isEligible: Bool
}

public struct PrestigeCommand: Codable, Equatable, Sendable {
    public let id: UUID

    public init(id: UUID) {
        self.id = id
    }
}

public enum PrestigeResult: Codable, Equatable, Sendable {
    case prestiged(preview: PrestigePreview, newPrestigeIndex: Int)
    case ineligible(preview: PrestigePreview)
    case duplicate
}

public enum PermanentUpgradeKind: String, Codable, CaseIterable, Sendable {
    case excavationMemory
    case resonanceDetection
    case compressedTime
}

public struct PermanentUpgradeCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let upgrade: PermanentUpgradeKind

    public init(id: UUID, upgrade: PermanentUpgradeKind) {
        self.id = id
        self.upgrade = upgrade
    }
}

public enum PermanentUpgradePurchaseResult: Codable, Equatable, Sendable {
    case purchased(upgrade: PermanentUpgradeKind, newLevel: Int, cost: Int)
    case insufficientShards(required: Int, available: Int)
    case maximumLevel
    case duplicate
    case invalidLevel
}

public enum PrestigeEngine {
    /// Segments the current run must break before a reset is offered.
    public static func target(prestigeIndex: Int) -> Int {
        let value = Balance.initialPrestigeTarget
            * pow(Balance.prestigeTargetGrowthRate, Double(max(0, prestigeIndex)))
        guard value.isFinite, value < Double(Int.max) else { return Int.max }
        return max(1, Int(value.rounded()))
    }

    public static func preview(for state: PlayerState) -> PrestigePreview {
        let target = target(prestigeIndex: state.prestigeIndex)
        return PrestigePreview(
            losses: PrestigeLossPreview(
                ore: state.resources.ore.doubleValue,
                runSegmentsBroken: state.runSegmentsBroken,
                equipment: state.equipment
            ),
            gains: PrestigeGainPreview(
                coreShards: shardGrant(runSegmentsBroken: state.runSegmentsBroken),
                keptDepthMeters: state.recordDepthMeters,
                rebuyDiscount: Balance.rememberedRebuyDiscount
            ),
            currentRunSegments: state.runSegmentsBroken,
            targetRunSegments: target,
            isEligible: state.runSegmentsBroken >= target
        )
    }

    @discardableResult
    public static func prestige(
        _ command: PrestigeCommand,
        in state: inout PlayerState
    ) -> PrestigeResult {
        guard !state.appliedPrestigeCommandIDs.contains(command.id) else { return .duplicate }
        let preview = preview(for: state)
        guard preview.isEligible else { return .ineligible(preview: preview) }

        state.resources.ore = 0
        state.resources.coreShards = saturatingAdd(
            state.resources.coreShards,
            preview.gains.coreShards
        )
        state.equipment = EquipmentLevels()
        state.equipmentModifications = .empty
        // Refinement resets with the levels that unlocked it. Keeping it would make a
        // reset pure profit and remove the decision prestige is supposed to be; the
        // remembered-level rebuy discount already covers the cost of climbing back.
        state.refinementTiers = .none
        state.runFocusCredits = 0
        state.runSegmentsBroken = 0
        // Back to the surface with the tools gone. Keeping the position while resetting
        // the equipment left the player facing rock they could no longer break, which is
        // a reset that costs everything and returns nothing (D-046). The ceiling, the
        // regions and the depth achievements all read `recordDepthMeters` and stay.
        state.mineFace = MineFaceState(
            lifetimeSegmentsBroken: state.mineFace.lifetimeSegmentsBroken,
            lifetimeSeamsBroken: state.mineFace.lifetimeSeamsBroken
        )
        if state.prestigeIndex < Int.max { state.prestigeIndex += 1 }
        state.appliedPrestigeCommandIDs.insert(command.id)
        return .prestiged(preview: preview, newPrestigeIndex: state.prestigeIndex)
    }

    public static func purchase(
        _ command: PermanentUpgradeCommand,
        in state: inout PlayerState
    ) -> PermanentUpgradePurchaseResult {
        guard !state.appliedPermanentUpgradeCommandIDs.contains(command.id) else {
            return .duplicate
        }
        let currentLevel = level(of: command.upgrade, in: state)
        guard currentLevel >= 0 else { return .invalidLevel }
        guard currentLevel < Balance.maximumPermanentUpgradeLevel else { return .maximumLevel }
        let nextLevel = currentLevel + 1
        guard state.resources.coreShards >= nextLevel else {
            return .insufficientShards(
                required: nextLevel,
                available: state.resources.coreShards
            )
        }
        state.resources.coreShards -= nextLevel
        setLevel(nextLevel, for: command.upgrade, in: &state)
        state.appliedPermanentUpgradeCommandIDs.insert(command.id)
        return .purchased(upgrade: command.upgrade, newLevel: nextLevel, cost: nextLevel)
    }

    public static func memoryMultiplier(level: Int) -> Double {
        let bounded = min(Balance.maximumPermanentUpgradeLevel, max(0, level))
        return Balance.compounded(Balance.excavationMemoryGrowthRate, bounded)
    }

    public static func compressedTimeBonus(level: Int) -> Double {
        let bounded = min(Balance.maximumPermanentUpgradeLevel, max(0, level))
        return Double(bounded) * Balance.compressedTimeLongSessionIncreasePerLevel
    }

    public static func applyingPermanentUpgrades(
        from state: PlayerState,
        to input: RewardInput
    ) -> RewardInput {
        RewardInput(
            completionID: input.completionID,
            outcome: input.outcome,
            sessionLength: input.sessionLength,
            plan: input.plan,
            verificationGrade: input.verificationGrade,
            growthFocusCredits: input.growthFocusCredits,
            streakDays: input.streakDays,
            dailySessionNumber: input.dailySessionNumber,
            equipment: input.equipment,
            vein: input.vein,
            resonanceBoostActive: input.resonanceBoostActive,
            permanentUpgrades: state.permanentUpgrades
        )
    }

    /// Scales with the run that was actually dug, so overshooting the target is never
    /// wasted and a later prestige is never worth less than an earlier one.
    static func shardGrant(runSegmentsBroken: Int) -> Int {
        guard runSegmentsBroken > 0 else { return 1 }
        let scaled = floor(Double(runSegmentsBroken) / Balance.prestigeShardSegmentDivisor)
        guard scaled.isFinite, scaled < Double(Int.max) else { return Int.max }
        return max(1, Int(scaled))
    }

    private static func level(of upgrade: PermanentUpgradeKind, in state: PlayerState) -> Int {
        switch upgrade {
        case .excavationMemory: state.excavationMemoryLevel
        case .resonanceDetection: state.permanentResonanceLevel
        case .compressedTime: state.compressedTimeLevel
        }
    }

    private static func setLevel(
        _ level: Int,
        for upgrade: PermanentUpgradeKind,
        in state: inout PlayerState
    ) {
        switch upgrade {
        case .excavationMemory: state.excavationMemoryLevel = level
        case .resonanceDetection: state.permanentResonanceLevel = level
        case .compressedTime: state.compressedTimeLevel = level
        }
    }

    private static func saturatingAdd(_ value: Int, _ addition: Int) -> Int {
        guard value >= 0 else { return addition }
        return value > Int.max - addition ? Int.max : value + addition
    }
}
