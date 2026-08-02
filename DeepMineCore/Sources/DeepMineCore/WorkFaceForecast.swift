import Foundation

/// What the current rock is worth and how long it has left.
///
/// A clicker's first screen has to answer "why am I hitting this" before it can ask for a
/// second tap. Reading it off the shaft is the whole point of D-056: the reward for the
/// layer in progress, the time it takes without any input, and the fact that both change
/// when equipment is bought.
public struct WorkFaceForecast: Equatable, Sendable {
    /// Ore the current segment pays when it breaks, with the freight modification applied.
    public let expectedOre: BigNumber
    public let remainingIntegrity: BigNumber
    /// Seconds for automation alone to break the rock. `nil` when nothing is automated —
    /// a cart at base level hauls nothing, and a fabricated ETA would promise idle income
    /// the player has not bought yet.
    public let automaticSecondsToBreak: TimeInterval?
    /// Current-segment-equivalent ore paid by automation each second. `nil` means the
    /// mine is genuinely manual; a very small or large rate remains a `BigNumber`
    /// instead of underflowing or saturating through `Double`.
    public let automaticOrePerSecond: BigNumber?
    /// Current segments crossed per second at the installed automation output.
    public let automaticLayersPerSecond: BigNumber?
    /// Taps needed at the current tap power, ignoring criticals and the impact meter so
    /// the number is a ceiling rather than an optimistic estimate.
    public let tapsToBreak: Int?

    public init(
        expectedOre: BigNumber,
        remainingIntegrity: BigNumber,
        automaticSecondsToBreak: TimeInterval?,
        automaticOrePerSecond: BigNumber? = nil,
        automaticLayersPerSecond: BigNumber? = nil,
        tapsToBreak: Int?
    ) {
        self.expectedOre = expectedOre
        self.remainingIntegrity = remainingIntegrity
        self.automaticSecondsToBreak = automaticSecondsToBreak
        self.automaticOrePerSecond = automaticOrePerSecond
        self.automaticLayersPerSecond = automaticLayersPerSecond
        self.tapsToBreak = tapsToBreak
    }

    public var isAutomated: Bool {
        automaticOrePerSecond != nil && automaticLayersPerSecond != nil
    }
}

/// The visible result of a purchase, derived from the two canonical player snapshots.
///
/// Keeping this comparison in Core prevents a notice from reconstructing economy rules
/// in SwiftUI. It also gives late-game values the same `BigNumber` range as the mine.
public struct PurchaseImpact: Equatable, Sendable {
    public enum Metric: Equatable, Sendable {
        case automaticETA(before: TimeInterval, after: TimeInterval)
        case tapOutput(before: BigNumber, after: BigNumber)
        case automaticOutput(before: BigNumber?, after: BigNumber)
    }

    public let equipment: EquipmentKind
    public let metric: Metric
    /// Fractional gain (`0.12` means +12%). `nil` when automation starts from zero,
    /// because dividing by a fabricated zero baseline would produce a false percentage.
    public let relativeIncrease: BigNumber?

    public init?(
        before: PlayerState,
        after: PlayerState,
        equipment: EquipmentKind
    ) {
        let beforeForecast = MiningLoop.forecast(for: before)
        let afterForecast = MiningLoop.forecast(for: after)
        let beforePower = MiningLoop.power(for: before)
        let afterPower = MiningLoop.power(for: after)

        self.equipment = equipment
        switch equipment {
        case .cart:
            let beforeRate = beforeForecast.automaticOrePerSecond
            guard let afterRate = afterForecast.automaticOrePerSecond else { return nil }
            if let beforeRate, afterRate <= beforeRate { return nil }
            relativeIncrease = Self.relativeGain(from: beforeRate, to: afterRate)
            if let beforeETA = beforeForecast.automaticSecondsToBreak,
               let afterETA = afterForecast.automaticSecondsToBreak,
               afterETA < beforeETA {
                metric = .automaticETA(before: beforeETA, after: afterETA)
            } else {
                metric = .automaticOutput(before: beforeRate, after: afterRate)
            }
        case .drill, .lamp:
            let beforeOutput = Self.expectedTapOutput(beforePower)
            let afterOutput = Self.expectedTapOutput(afterPower)
            guard afterOutput > beforeOutput else { return nil }
            metric = .tapOutput(before: beforeOutput, after: afterOutput)
            relativeIncrease = Self.relativeGain(from: beforeOutput, to: afterOutput)
        }
    }

    private static func expectedTapOutput(_ power: StrikePower) -> BigNumber {
        let expectedCritical = BigNumber.one
            + (power.criticalDamageMultiplier - .one) * power.criticalChance
        return power.tapDamage * expectedCritical
    }

    private static func relativeGain(
        from before: BigNumber?,
        to after: BigNumber
    ) -> BigNumber? {
        guard let before, before > .zero, after > before else { return nil }
        return after / before - .one
    }
}

/// Refinement feedback derived from the installed tier and the exact Core output it changes.
///
/// Lamp refinement reports the actual total critical-multiplier ratio, not the raw tier
/// coefficient. The level and permanent additive terms sit outside Core's square-root
/// refinement factor, so promising an unconditional `sqrt(2.5)` gain would be misleading.
public struct RefinementImpact: Equatable, Sendable {
    public let equipment: EquipmentKind
    public let beforeTier: Int
    public let afterTier: Int
    public let coreMultiplier: BigNumber
    public let purchaseImpact: PurchaseImpact

    public init?(
        before: PlayerState,
        after: PlayerState,
        equipment: EquipmentKind
    ) {
        let beforeTier = before.refinementTiers.tier(for: equipment)
        let afterTier = after.refinementTiers.tier(for: equipment)
        guard afterTier > beforeTier,
              let purchaseImpact = PurchaseImpact(
                before: before,
                after: after,
                equipment: equipment
              ) else { return nil }

        guard let multiplier = Self.outputMultiplier(
            before: before,
            after: after,
            equipment: equipment
        ), multiplier > .one else { return nil }

        self.equipment = equipment
        self.beforeTier = beforeTier
        self.afterTier = afterTier
        self.coreMultiplier = multiplier
        self.purchaseImpact = purchaseImpact
    }

    public static func coreMultiplier(
        for equipment: EquipmentKind,
        in state: PlayerState,
        tiersAdvanced: Int = 1
    ) -> BigNumber {
        guard tiersAdvanced > 0 else { return .one }
        let currentTier = state.refinementTiers.tier(for: equipment)
        guard currentTier <= Int.max - tiersAdvanced else { return .one }
        let targetTier = currentTier + tiersAdvanced
        let requiredLevel = RefinementEngine.requiredLevel(forTier: targetTier)
        var before = state
        switch equipment {
        case .drill:
            before.equipment.drill = max(before.equipment.drill, requiredLevel)
        case .cart:
            before.equipment.cart = max(before.equipment.cart, requiredLevel)
        case .lamp:
            before.equipment.lamp = max(before.equipment.lamp, requiredLevel)
        }
        var after = before
        switch equipment {
        case .drill: after.refinementTiers.drill = targetTier
        case .cart: after.refinementTiers.cart = targetTier
        case .lamp: after.refinementTiers.lamp = targetTier
        }
        return outputMultiplier(before: before, after: after, equipment: equipment) ?? .one
    }

    private static func outputMultiplier(
        before: PlayerState,
        after: PlayerState,
        equipment: EquipmentKind
    ) -> BigNumber? {
        let beforePower = MiningLoop.power(for: before)
        let afterPower = MiningLoop.power(for: after)
        let values: (before: BigNumber, after: BigNumber)
        switch equipment {
        case .drill:
            values = (beforePower.tapDamage, afterPower.tapDamage)
        case .cart:
            values = (beforePower.damagePerSecond, afterPower.damagePerSecond)
        case .lamp:
            values = (
                beforePower.criticalDamageMultiplier,
                afterPower.criticalDamageMultiplier
            )
        }
        guard values.before > .zero, values.after > values.before else { return nil }
        return values.after / values.before
    }
}

extension MiningLoop {
    public static func forecast(for state: PlayerState) -> WorkFaceForecast {
        let power = power(for: state)
        let remaining = state.mineFace.remainingIntegrity
        let oreMultiplier = max(1, power.oreMultiplier)
        let expectedOre = state.mineFace.segment.oreYield * oreMultiplier

        let layerRate: BigNumber?
        let oreRate: BigNumber?
        let maximumIntegrity = state.mineFace.segment.maximumIntegrity
        if power.damagePerSecond > .zero, maximumIntegrity > .zero {
            let rate = power.damagePerSecond / maximumIntegrity
            layerRate = rate
            oreRate = expectedOre * rate
        } else {
            layerRate = nil
            oreRate = nil
        }

        let seconds: TimeInterval?
        if power.damagePerSecond > .zero, remaining > .zero {
            seconds = Self.displayableCount(remaining / power.damagePerSecond)
        } else {
            seconds = nil
        }

        let taps: Int?
        if power.tapDamage > .zero, remaining > .zero {
            let value = Self.displayableCount(remaining / power.tapDamage)
            taps = value.flatMap {
                let rounded = $0.rounded(.up)
                guard rounded < Double(Int.max) else { return nil }
                return max(1, Int(rounded))
            }
        } else {
            taps = nil
        }

        return WorkFaceForecast(
            expectedOre: expectedOre,
            remainingIntegrity: remaining,
            automaticSecondsToBreak: seconds,
            automaticOrePerSecond: oreRate,
            automaticLayersPerSecond: layerRate,
            tapsToBreak: taps
        )
    }

    /// UI counts eventually have to become `Int` for a duration or tap label. Reject a
    /// value before `BigNumber.doubleValue` saturates so callers can fall back to rate
    /// output without misclassifying an automated mine as manual.
    private static func displayableCount(_ value: BigNumber) -> Double? {
        guard value > .zero,
              let magnitude = value.log10Value,
              magnitude < log10(Double(Int.max)) else { return nil }
        let result = value.doubleValue
        return result.isFinite && result > 0 && result < Double(Int.max) ? result : nil
    }
}
