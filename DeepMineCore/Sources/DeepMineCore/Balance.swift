import Foundation

public enum Balance {
    // The practice dig exists to show the return, not to be a real session. Ninety
    // seconds of waiting before the first reward is a long time to ask of someone who
    // has not seen the game yet.
    public static let demoDurationSeconds: TimeInterval = 10
    public static let demoOreGrant = 100.0
    /// The practice return always finds a vein. Leaving the first impression to a 12%
    /// roll means most players never see the mechanic the game is built around.
    ///
    /// A crystal vein specifically: the practice ore grant is a flat amount, so a blue
    /// vein would promise a x1.5 haul the demo does not actually pay. The crystal is
    /// really handed over.
    public static let demoGuaranteedVein = VeinKind.crystal
    public static let baseOrePerFocusCredit = 100.0
    public static let minutesPerFocusCredit = 25.0
    public static let growthRate = 1.04
    public static let maximumGrowthFocusCredits = 20.0

    public static let shortSessionMinutes = 15
    public static let standardSessionMinutes = 25
    public static let longSessionMinutes = 50
    public static let shortSessionMultiplier = 1.0
    public static let standardSessionMultiplier = 1.10
    public static let longSessionMultiplier = 1.30

    public static let safePlanMultiplier = 1.0
    public static let deepPlanMultiplier = 1.6
    public static let surveyPlanMultiplier = 0.8

    public static let sealedVerificationMultiplier = 1.0
    public static let openVerificationMultiplier = 0.75
    public static let collapsedVerificationMultiplier = 0.5
    public static let deepCollapseMultiplier = 0.0

    public static let abandonmentMultiplier = 0.5

    public static let streakDayThree = 3
    public static let streakDaySeven = 7
    public static let streakDayFourteen = 14
    public static let streakDayThirty = 30
    public static let streakOneMultiplier = 1.0
    public static let streakThreeMultiplier = 1.10
    public static let streakSevenMultiplier = 1.25
    public static let streakFourteenMultiplier = 1.40
    public static let streakThirtyMultiplier = 1.60
    public static let minimumDailyGoalMinutes = 25
    public static let maximumDailyGoalMinutes = 360
    public static let dailyGoalStepMinutes = 5
    public static let defaultDailyGoalMinutes = 100
    public static let missedDayStreakDivisor = 2

    public static let firstDailySessionMultiplier = 1.0
    public static let secondDailySessionMultiplier = 1.05
    public static let laterDailySessionMultiplier = 1.10

    public static let minimumEquipmentLevel = 1
    // A clicker's ladder has to outlast the rock. At 60 the ceiling bound before the
    // abyss and froze both tap and automation damage while the rock kept hardening,
    // which is what stalled the descent (D-044).
    public static let maximumEquipmentLevel = 200
    // Compounding effects keep every level worth the same relative gain. Linear
    // per-level bonuses decayed to +3.6% at the top while price kept multiplying,
    // which stalled the economy well before the level cap.
    public static let drillRewardGrowthRate = 1.12
    public static let standardCartGrowthRate = 1.05
    public static let longCartGrowthRate = 1.07
    public static let lampVeinChanceIncreasePerLevel = 0.012
    public static let equipmentPriceGrowthRate = 1.34
    public static let drillBasePrice = 100.0
    public static let cartBasePrice = 180.0
    public static let lampBasePrice = 200.0
    // Spec §4.5: depth unlocks the equipment level ceiling. The rail only binds
    // during the first weeks, where ore alone would let a heavy schedule sprint
    // through the whole ladder.
    //
    // The step is set so the rail never binds on ore the player dug themselves: ore
    // compounds at 1.07 per segment and a level costs 1.34, which buys ~0.23 levels
    // per segment, while 15m per level grants ~0.27. Focus ore arrives from outside
    // the rock, so the rail still catches a session-fuelled sprint (D-044).
    public static let equipmentLevelUnlockBase = 5
    public static let equipmentLevelUnlockDepthStep = 15
    // Prestige remembers the shaft it already dug: levels at or below the previous
    // peak cost half, so a reset costs days instead of weeks.
    public static let rememberedRebuyDiscount = 0.5

    // Crew size is display only. It never enters a reward formula.
    public static let minerCrewStep = 5
    public static let maximumMinerCrew = 12

    public static let depthCoefficient = 12.0
    public static let depthExponent = 1.15
    public static let deepUnlockCompletedSessions = 3
    public static let sessionHistoryLimit = 500
    public static let dailyRecordLimit = 730

    public static let baseVeinChance = 0.12
    public static let surveyVeinChanceMultiplier = 3.0
    public static let maximumVeinChance = 1.0
    public static let permanentResonanceChanceIncreasePerLevel = 0.01
    public static let drySpellBoostStartsAfterMisses = 4
    public static let drySpellChanceIncreasePerAttempt = 0.08
    public static let guaranteedVeinAfterMisses = 7
    public static let blueVeinTypeWeight = 0.35
    public static let crystalVeinTypeWeight = 0.25
    public static let vaultVeinTypeWeight = 0.15
    public static let resonanceVeinTypeWeight = 0.15
    public static let abyssVeinTypeWeight = 0.10
    public static let blueVeinRewardMultiplier = 1.5
    public static let resonanceRewardMultiplier = 2.0
    // Ore-equivalent weights, in units of one session's ore, used only to rank
    // upgrades. Blue and resonance are exact; the unlock veins are design weights
    // so the advisor stops valuing the lamp at zero.
    public static let blueVeinAdvisorWeight = blueVeinRewardMultiplier - 1
    public static let resonanceVeinAdvisorWeight = resonanceRewardMultiplier - 1
    public static let unlockVeinAdvisorWeight = 0.5
    public static let crystalRegionBaseQuantity = 1
    public static let vaultCrystalConversionQuantity = 2
    public static let abyssBonusDepthMeters = 60
    // Region gates are set against how fast the rock is actually broken, not against the
    // old focus-derived depth. Entry lasts a first sitting, the crystal seam a few days,
    // and the abyss stays a month or two out for a player who mostly idles (D-044).
    public static let crystalRegionDepth = 240
    public static let ruinsRegionDepth = 800
    public static let abyssRegionDepth = 1_600
    /// Segments broken in the current run. Focus credits cannot gate a reset in a game
    /// that is playable without focus at all (D-045).
    public static let initialPrestigeTarget = 120.0
    public static let prestigeTargetGrowthRate = 1.5
    public static let maximumPermanentUpgradeLevel = 10
    public static let excavationMemoryGrowthRate = 1.08
    public static let compressedTimeLongSessionIncreasePerLevel = 0.05
    // A run that overshoots its target is worth more shards than one that barely
    // reached it, so a long run is never wasted by prestiging late.
    public static let prestigeShardSegmentDivisor = 40.0
    public static let clockTamperThreshold: TimeInterval = 30
    public static let nanosecondsPerSecond = 1_000_000_000.0
    public static let passiveSnapshotFreshnessSeconds: TimeInterval = 15 * 60
    public static let completedActivityRetentionSeconds: TimeInterval = 4 * 60 * 60
    public static let activityContentMaximumBytes = 4_096

    public static func minutes(for length: SessionLength) -> Int {
        switch length {
        case .minutes15: shortSessionMinutes
        case .minutes25: standardSessionMinutes
        case .minutes50: longSessionMinutes
        }
    }

    public static func lengthMultiplier(for length: SessionLength) -> Double {
        switch length {
        case .minutes15: shortSessionMultiplier
        case .minutes25: standardSessionMultiplier
        case .minutes50: longSessionMultiplier
        }
    }

    public static func planMultiplier(for plan: MinePlan) -> Double {
        switch plan {
        case .safe: safePlanMultiplier
        case .deep: deepPlanMultiplier
        case .survey: surveyPlanMultiplier
        }
    }

    public static func verificationMultiplier(
        for grade: VerificationGrade,
        plan: MinePlan
    ) -> Double {
        switch grade {
        case .sealed: sealedVerificationMultiplier
        case .open: openVerificationMultiplier
        case .collapsed:
            plan == .deep ? deepCollapseMultiplier : collapsedVerificationMultiplier
        }
    }

    public static func streakMultiplier(days: Int) -> Double {
        switch days {
        case streakDayThirty...: streakThirtyMultiplier
        case streakDayFourteen...: streakFourteenMultiplier
        case streakDaySeven...: streakSevenMultiplier
        case streakDayThree...: streakThreeMultiplier
        default: streakOneMultiplier
        }
    }

    public static func dailySessionMultiplier(number: Int) -> Double {
        switch number {
        case 1: firstDailySessionMultiplier
        case 2: secondDailySessionMultiplier
        default: laterDailySessionMultiplier
        }
    }

    public static func equipmentMultiplier(
        levels: EquipmentLevels,
        length: SessionLength
    ) -> Double {
        drillMultiplier(level: levels.drill) * cartMultiplier(level: levels.cart, length: length)
    }

    public static func drillMultiplier(level: Int) -> Double {
        compounded(drillRewardGrowthRate, levelsAboveBase(level))
    }

    /// The cart only pays off on the promises that are hard to keep, so a 15 minute
    /// session gets nothing from it.
    public static func cartMultiplier(level: Int, length: SessionLength) -> Double {
        switch length {
        case .minutes15: 1
        case .minutes25: compounded(standardCartGrowthRate, levelsAboveBase(level))
        case .minutes50: compounded(longCartGrowthRate, levelsAboveBase(level))
        }
    }

    public static func maximumEquipmentLevel(forDepth depth: Int) -> Int {
        let unlocked = equipmentLevelUnlockBase
            + max(0, depth) / equipmentLevelUnlockDepthStep
        return min(maximumEquipmentLevel, max(minimumEquipmentLevel, unlocked))
    }

    static func levelsAboveBase(_ level: Int) -> Int {
        max(0, min(maximumEquipmentLevel, level) - minimumEquipmentLevel)
    }

    static func compounded(_ rate: Double, _ exponent: Int) -> Double {
        let value = pow(rate, Double(exponent))
        return value.isFinite ? value : Double.greatestFiniteMagnitude
    }

    /// Expected ore multiplier of one vein roll, in ore-equivalent terms.
    public static func expectedVeinMultiplier(chance: Double) -> Double {
        let weighted = blueVeinTypeWeight * blueVeinAdvisorWeight
            + resonanceVeinTypeWeight * resonanceVeinAdvisorWeight
            + (crystalVeinTypeWeight + vaultVeinTypeWeight + abyssVeinTypeWeight)
            * unlockVeinAdvisorWeight
        return 1 + min(maximumVeinChance, max(0, chance)) * weighted
    }

    public static func veinMultiplier(vein: VeinKind?, resonanceBoostActive: Bool) -> Double {
        let foundVein = vein == .blue ? blueVeinRewardMultiplier : 1
        let resonance = resonanceBoostActive ? resonanceRewardMultiplier : 1
        return foundVein * resonance
    }

    public static func equipmentBasePrice(for equipment: EquipmentKind) -> Double {
        switch equipment {
        case .drill: drillBasePrice
        case .cart: cartBasePrice
        case .lamp: lampBasePrice
        }
    }
}
