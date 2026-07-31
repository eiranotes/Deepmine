import Foundation

public struct SeededGenerator: RandomNumberGenerator, Codable, Equatable, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

public struct VeinRollResult: Codable, Equatable, Sendable {
    public let wasEligible: Bool
    public let chance: Double
    public let vein: VeinKind?
    public let wasGuaranteed: Bool

    public init(
        wasEligible: Bool,
        chance: Double,
        vein: VeinKind?,
        wasGuaranteed: Bool
    ) {
        self.wasEligible = wasEligible
        self.chance = chance
        self.vein = vein
        self.wasGuaranteed = wasGuaranteed
    }
}

public enum VeinEngine {
    public static func chance(
        plan: MinePlan,
        lampLevel: Int,
        permanentResonanceLevel: Int,
        consecutiveMisses: Int
    ) -> Double {
        let planBase = Balance.baseVeinChance
            * (plan == .survey ? Balance.surveyVeinChanceMultiplier : 1)
        let lamp = Double(max(0, lampLevel - Balance.minimumEquipmentLevel))
            * Balance.lampVeinChanceIncreasePerLevel
        let permanent = Double(max(0, permanentResonanceLevel))
            * Balance.permanentResonanceChanceIncreasePerLevel
        let drySteps = consecutiveMisses >= Balance.drySpellBoostStartsAfterMisses
            ? consecutiveMisses - Balance.drySpellBoostStartsAfterMisses + 1
            : 0
        let drySpell = Double(drySteps) * Balance.drySpellChanceIncreasePerAttempt
        return min(Balance.maximumVeinChance, max(0, planBase + lamp + permanent + drySpell))
    }

    public static func rollAfterCompletion<R: RandomNumberGenerator>(
        outcome: SessionOutcome,
        plan: MinePlan,
        state: inout PlayerState,
        using generator: inout R
    ) -> VeinRollResult {
        rollAfterCompletion(
            outcome: outcome,
            plan: plan,
            lampLevel: state.equipment.lamp,
            permanentResonanceLevel: state.permanentResonanceLevel,
            consecutiveMisses: &state.consecutiveVeinMisses,
            using: &generator
        )
    }

    public static func rollAfterCompletion<R: RandomNumberGenerator>(
        outcome: SessionOutcome,
        plan: MinePlan,
        lampLevel: Int,
        permanentResonanceLevel: Int,
        consecutiveMisses: inout Int,
        using generator: inout R
    ) -> VeinRollResult {
        guard case .completed = outcome else {
            return VeinRollResult(
                wasEligible: false,
                chance: 0,
                vein: nil,
                wasGuaranteed: false
            )
        }
        let calculatedChance = chance(
            plan: plan,
            lampLevel: lampLevel,
            permanentResonanceLevel: permanentResonanceLevel,
            consecutiveMisses: consecutiveMisses
        )
        let guaranteed = consecutiveMisses >= Balance.guaranteedVeinAfterMisses
        let probability = guaranteed ? Balance.maximumVeinChance : calculatedChance
        let found = guaranteed || unitInterval(using: &generator) < probability
        if found {
            let vein = rollKind(using: &generator)
            consecutiveMisses = 0
            return VeinRollResult(
                wasEligible: true,
                chance: probability,
                vein: vein,
                wasGuaranteed: guaranteed
            )
        }
        if consecutiveMisses < Int.max { consecutiveMisses += 1 }
        return VeinRollResult(
            wasEligible: true,
            chance: probability,
            vein: nil,
            wasGuaranteed: false
        )
    }

    public static func rollKind<R: RandomNumberGenerator>(using generator: inout R) -> VeinKind {
        let value = unitInterval(using: &generator)
        let crystalBoundary = Balance.blueVeinTypeWeight + Balance.crystalVeinTypeWeight
        let vaultBoundary = crystalBoundary + Balance.vaultVeinTypeWeight
        let resonanceBoundary = vaultBoundary + Balance.resonanceVeinTypeWeight
        switch value {
        case ..<Balance.blueVeinTypeWeight: return .blue
        case ..<crystalBoundary: return .crystal
        case ..<vaultBoundary: return .vault
        case ..<resonanceBoundary: return .resonance
        default: return .abyss
        }
    }

    public static func applying(vein: VeinKind?, to input: RewardInput) -> RewardInput {
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
            vein: vein,
            resonanceBoostActive: input.resonanceBoostActive,
            permanentUpgrades: input.permanentUpgrades
        )
    }

    private static func unitInterval<R: RandomNumberGenerator>(using generator: inout R) -> Double {
        Double(generator.next() >> 11) / 9_007_199_254_740_992
    }
}
