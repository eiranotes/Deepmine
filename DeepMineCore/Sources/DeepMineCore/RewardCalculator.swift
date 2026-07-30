import Foundation

public enum FatigueCalculator {
    public static func breakdown(
        startingDailyMinutes: Int,
        sessionMinutes: Int
    ) -> FatigueBreakdown {
        let start = max(0, startingDailyMinutes)
        var position = start
        var remaining = max(0, sessionMinutes)
        var segments: [FatigueSegment] = []

        while remaining > 0 {
            let boundary: Int?
            let multiplier: Double
            if position < Balance.firstFatigueThresholdMinutes {
                boundary = Balance.firstFatigueThresholdMinutes
                multiplier = Balance.freshFatigueMultiplier
            } else if position < Balance.secondFatigueThresholdMinutes {
                boundary = Balance.secondFatigueThresholdMinutes
                multiplier = Balance.tiredFatigueMultiplier
            } else {
                boundary = nil
                multiplier = Balance.exhaustedFatigueMultiplier
            }

            let minutes = boundary.map { min(remaining, $0 - position) } ?? remaining
            segments.append(FatigueSegment(
                startMinute: position,
                minutes: minutes,
                multiplier: multiplier
            ))
            position += minutes
            remaining -= minutes
        }

        guard sessionMinutes > 0 else {
            return FatigueBreakdown(segments: [], effectiveMultiplier: 1)
        }
        let weightedMinutes = segments.reduce(0.0) {
            $0 + Double($1.minutes) * $1.multiplier
        }
        return FatigueBreakdown(
            segments: segments,
            effectiveMultiplier: weightedMinutes / Double(sessionMinutes)
        )
    }
}

public enum RewardCalculator {
    public static func calculate(_ input: RewardInput) throws -> RewardResult {
        try validate(input)
        let focusedMinutes = try focusedMinutes(for: input)
        let focusCredits = Double(focusedMinutes) / Balance.minutesPerFocusCredit
        let baseOre = finiteProduct([Balance.baseOrePerFocusCredit, focusCredits])
        let growth = growthMultiplier(focusCredits: input.growthFocusCredits)
        let length = lengthMultiplier(
            for: input.outcome,
            chosenLength: input.sessionLength,
            compressedTimeLevel: input.permanentUpgrades.compressedTime
        )
        let plan = Balance.planMultiplier(for: input.plan)
        let verification = Balance.verificationMultiplier(
            for: input.verificationGrade,
            plan: input.plan
        )
        let streak = Balance.streakMultiplier(days: input.streakDays)
        let dailyOrder = Balance.dailySessionMultiplier(number: input.dailySessionNumber)
        let equipmentLength: SessionLength
        switch input.outcome {
        case .completed: equipmentLength = input.sessionLength
        case .abandoned: equipmentLength = .minutes15
        }
        let equipment = Balance.equipmentMultiplier(
            levels: input.equipment,
            length: equipmentLength
        )
        let vein = Balance.veinMultiplier(
            vein: input.vein,
            resonanceBoostActive: input.resonanceBoostActive
        )
        let fatigue = FatigueCalculator.breakdown(
            startingDailyMinutes: input.startingDailyMinutes,
            sessionMinutes: focusedMinutes
        )
        let abandonment = abandonmentMultiplier(for: input)
        let permanent = PrestigeEngine.memoryMultiplier(
            level: input.permanentUpgrades.excavationMemory
        )
        let breakdown = RewardMultiplierBreakdown(
            focusCredits: focusCredits,
            baseOre: baseOre,
            growth: growth,
            length: length,
            plan: plan,
            verification: verification,
            streak: streak,
            dailyOrder: dailyOrder,
            equipment: equipment,
            vein: vein,
            fatigue: fatigue.effectiveMultiplier,
            abandonment: abandonment,
            permanent: permanent,
            fatigueSegments: fatigue.segments
        )
        let ore = finiteProduct([baseOre, breakdown.combinedMultiplier])
        return RewardResult(
            completionID: input.completionID,
            focusedMinutes: focusedMinutes,
            focusCredits: focusCredits,
            ore: ore,
            breakdown: breakdown,
            wasDuplicate: false
        )
    }

    public static func award(
        _ input: RewardInput,
        using registry: inout CompletionRegistry
    ) throws -> RewardResult {
        let calculated = try calculate(input)
        guard registry.claim(input.completionID) else {
            return RewardResult(
                completionID: calculated.completionID,
                focusedMinutes: calculated.focusedMinutes,
                focusCredits: calculated.focusCredits,
                ore: 0,
                breakdown: calculated.breakdown,
                wasDuplicate: true
            )
        }
        return calculated
    }

    private static func validate(_ input: RewardInput) throws {
        guard input.growthFocusCredits.isFinite, input.growthFocusCredits >= 0 else {
            throw RewardCalculationError.invalidValue(field: "growthFocusCredits")
        }
        guard input.streakDays >= 0 else {
            throw RewardCalculationError.invalidValue(field: "streakDays")
        }
        guard input.dailySessionNumber >= 1 else {
            throw RewardCalculationError.invalidValue(field: "dailySessionNumber")
        }
        guard input.startingDailyMinutes >= 0 else {
            throw RewardCalculationError.invalidValue(field: "startingDailyMinutes")
        }
        let validPermanentLevels = 0...Balance.maximumPermanentUpgradeLevel
        guard validPermanentLevels.contains(input.permanentUpgrades.excavationMemory),
              validPermanentLevels.contains(input.permanentUpgrades.resonanceDetection),
              validPermanentLevels.contains(input.permanentUpgrades.compressedTime) else {
            throw RewardCalculationError.invalidValue(field: "permanentUpgrades")
        }
        let validLevels = Balance.minimumEquipmentLevel...Balance.maximumEquipmentLevel
        guard validLevels.contains(input.equipment.drill),
              validLevels.contains(input.equipment.cart),
              validLevels.contains(input.equipment.lamp) else {
            throw RewardCalculationError.invalidValue(field: "equipment")
        }
    }

    static func growthMultiplier(focusCredits: Double) -> Double {
        let exponent = min(max(0, focusCredits), Balance.maximumGrowthFocusCredits)
        return finitePower(Balance.growthRate, exponent)
    }

    private static func focusedMinutes(for input: RewardInput) throws -> Int {
        switch input.outcome {
        case .completed:
            return input.sessionLength.minutes
        case .abandoned(let elapsedMinutes):
            guard elapsedMinutes >= 0, elapsedMinutes <= input.sessionLength.minutes else {
                throw RewardCalculationError.invalidValue(field: "elapsedMinutes")
            }
            return elapsedMinutes
        }
    }

    private static func lengthMultiplier(
        for outcome: SessionOutcome,
        chosenLength: SessionLength,
        compressedTimeLevel: Int
    ) -> Double {
        switch outcome {
        case .completed:
            let compressed = chosenLength == .minutes50
                ? Double(compressedTimeLevel) * Balance.compressedTimeLongSessionIncreasePerLevel
                : 0
            return Balance.lengthMultiplier(for: chosenLength) + compressed
        case .abandoned: return Balance.shortSessionMultiplier
        }
    }

    private static func abandonmentMultiplier(for input: RewardInput) -> Double {
        guard case .abandoned = input.outcome else { return 1 }
        if input.plan == .deep { return 0 }
        return input.verificationGrade == .collapsed ? 1 : Balance.abandonmentMultiplier
    }

    private static func finitePower(_ base: Double, _ exponent: Double) -> Double {
        let value = pow(base, exponent)
        return value.isFinite ? value : Double.greatestFiniteMagnitude
    }

    private static func finiteProduct(_ values: [Double]) -> Double {
        values.reduce(1.0) { partial, next in
            guard partial != 0, next != 0 else { return 0 }
            guard partial <= Double.greatestFiniteMagnitude / next else {
                return Double.greatestFiniteMagnitude
            }
            return partial * next
        }
    }
}
