import Foundation

public enum UpgradeAdvisor {
    public static func recommend(
        for state: PlayerState,
        marginalExpectedOre: [EquipmentKind: Double]
    ) -> UpgradeRecommendation? {
        let unlocked = EquipmentEngine.unlockedMaximumLevel(in: state)
        var best: UpgradeRecommendation?
        for equipment in EquipmentKind.allCases {
            guard let quote = EquipmentEngine.quote(for: equipment, in: state),
                  quote.currentLevel < unlocked,
                  state.resources.ore >= quote.cost,
                  let marginal = marginalExpectedOre[equipment],
                  marginal.isFinite, marginal > 0 else { continue }
            let candidate = UpgradeRecommendation(
                equipment: equipment,
                currentLevel: quote.currentLevel,
                nextLevel: quote.currentLevel + 1,
                cost: quote.cost,
                marginalExpectedOre: marginal,
                efficiency: marginal / quote.cost,
                isRemembered: quote.isRemembered
            )
            if best == nil || candidate.efficiency > best!.efficiency {
                best = candidate
            }
        }
        return best
    }

    /// Recommends the purchase that most improves the mine the player is looking at.
    ///
    /// The previous home recommendation optimized the next focus-session payout. That
    /// regularly pointed at the drill while the cart still produced zero automatic
    /// damage, delaying the idle game's defining unlock. This score uses the same
    /// `StrikePower` that drives taps and automation, so the home button now answers the
    /// question shown on screen: which affordable purchase makes this rock move faster?
    public static func recommendForMining(for state: PlayerState) -> UpgradeRecommendation? {
        let unlocked = EquipmentEngine.unlockedMaximumLevel(in: state)
        let current = MiningLoop.power(for: state)
        let currentTap = expectedTapDamage(current)
        var best: UpgradeRecommendation?

        for equipment in EquipmentKind.allCases {
            guard let quote = EquipmentEngine.quote(for: equipment, in: state),
                  quote.currentLevel < unlocked,
                  state.resources.ore >= quote.cost else { continue }

            var upgraded = state
            switch equipment {
            case .drill: upgraded.equipment.drill += 1
            case .cart: upgraded.equipment.cart += 1
            case .lamp: upgraded.equipment.lamp += 1
            }
            let projected = MiningLoop.power(for: upgraded)
            let tapGain = relativeGain(from: currentTap, to: expectedTapDamage(projected))
            let automaticGain = relativeAutomaticGain(
                from: current.damagePerSecond,
                to: projected.damagePerSecond
            )
            let oreGain = max(0, projected.oreMultiplier / max(1, current.oreMultiplier) - 1)

            // Automatic output receives the largest weight because it advances the same
            // mine while the app is open and while it is closed. Tap output remains the
            // primary active-play axis; ore multipliers are valuable but secondary.
            let marginal = tapGain + automaticGain * 1.5 + oreGain * 0.75
            guard marginal.isFinite, marginal > 0 else { continue }

            let candidate = UpgradeRecommendation(
                equipment: equipment,
                currentLevel: quote.currentLevel,
                nextLevel: quote.currentLevel + 1,
                cost: quote.cost,
                marginalExpectedOre: marginal,
                efficiency: marginal / quote.cost,
                isRemembered: quote.isRemembered
            )
            if best == nil || candidate.efficiency > best!.efficiency {
                best = candidate
            }
        }
        return best
    }

    public static func recommend(
        for state: PlayerState,
        nextSession: RewardInput,
        additionalVeinChance: Double = 0
    ) throws -> UpgradeRecommendation? {
        recommend(
            for: state,
            marginalExpectedOre: try marginalExpectedOre(
                for: state,
                nextSession: nextSession,
                additionalVeinChance: additionalVeinChance
            )
        )
    }

    public static func marginalExpectedOre(
        for state: PlayerState,
        nextSession: RewardInput,
        additionalVeinChance: Double = 0
    ) throws -> [EquipmentKind: Double] {
        let current = try expectedOre(
            input: nextSession,
            equipment: state.equipment,
            growthFocusCredits: state.lifetimeFocusCredits,
            additionalVeinChance: additionalVeinChance
        )
        var values: [EquipmentKind: Double] = [:]
        let unlocked = EquipmentEngine.unlockedMaximumLevel(in: state)
        for equipment in EquipmentKind.allCases {
            let level = EquipmentEngine.level(of: equipment, in: state.equipment)
            guard level < unlocked else { continue }
            var upgraded = state.equipment
            switch equipment {
            case .drill: upgraded.drill += 1
            case .cart: upgraded.cart += 1
            case .lamp: upgraded.lamp += 1
            }
            let projected = try expectedOre(
                input: nextSession,
                equipment: upgraded,
                growthFocusCredits: state.lifetimeFocusCredits,
                additionalVeinChance: additionalVeinChance
            )
            values[equipment] = max(0, projected - current)
        }
        return values
    }

    private static func expectedTapDamage(_ power: StrikePower) -> BigNumber {
        let expectedCritical = 1 + power.criticalChance * (power.criticalMultiplier - 1)
        return power.tapDamage * max(1, expectedCritical)
    }

    private static func relativeGain(from current: BigNumber, to projected: BigNumber) -> Double {
        guard current > .zero, projected > current else { return 0 }
        let ratio = (projected / current).doubleValue
        return ratio.isFinite ? max(0, ratio - 1) : Double.greatestFiniteMagnitude
    }

    private static func relativeAutomaticGain(
        from current: BigNumber,
        to projected: BigNumber
    ) -> Double {
        guard projected > current else { return 0 }
        // Moving from no automation to any automation is a categorical unlock. A finite
        // score keeps ordering deterministic while making it dominate incremental gains.
        if current.isZero { return 10 }
        return relativeGain(from: current, to: projected)
    }

    private static func expectedOre(
        input: RewardInput,
        equipment: EquipmentLevels,
        growthFocusCredits: Double,
        additionalVeinChance: Double
    ) throws -> Double {
        let projection = RewardInput(
            completionID: input.completionID,
            outcome: input.outcome,
            sessionLength: input.sessionLength,
            plan: input.plan,
            verificationGrade: input.verificationGrade,
            growthFocusCredits: growthFocusCredits,
            streakDays: input.streakDays,
            dailySessionNumber: input.dailySessionNumber,
            equipment: equipment,
            vein: nil,
            resonanceBoostActive: input.resonanceBoostActive,
            permanentUpgrades: input.permanentUpgrades
        )
        let baseOre = try RewardCalculator.calculate(projection).ore
        let planChance = Balance.baseVeinChance
            * (input.plan == .survey ? Balance.surveyVeinChanceMultiplier : 1)
        let permanentChance = Double(input.permanentUpgrades.resonanceDetection)
            * Balance.permanentResonanceChanceIncreasePerLevel
        let chance = min(
            Balance.maximumVeinChance,
            max(0, planChance + EquipmentEngine.lampChanceBonus(level: equipment.lamp)
                + permanentChance + additionalVeinChance)
        )
        let multiplier = Balance.expectedVeinMultiplier(chance: chance)
        guard baseOre <= Double.greatestFiniteMagnitude / multiplier else {
            return Double.greatestFiniteMagnitude
        }
        return baseOre * multiplier
    }
}
