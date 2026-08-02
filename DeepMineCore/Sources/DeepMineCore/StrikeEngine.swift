import Foundation

public struct StrikePower: Equatable, Sendable {
    public let tapDamage: BigNumber
    public let damagePerSecond: BigNumber
    public let criticalChance: Double
    public let criticalMultiplier: Double
    public let criticalDamageMultiplier: BigNumber
    public let oreMultiplier: Double

    public init(
        tapDamage: BigNumber,
        damagePerSecond: BigNumber,
        criticalChance: Double,
        criticalMultiplier: Double,
        criticalDamageMultiplier: BigNumber? = nil,
        oreMultiplier: Double = 1
    ) {
        self.tapDamage = tapDamage
        self.damagePerSecond = damagePerSecond
        self.criticalChance = criticalChance
        self.criticalMultiplier = criticalMultiplier
        self.criticalDamageMultiplier = criticalDamageMultiplier ?? BigNumber(criticalMultiplier)
        self.oreMultiplier = oreMultiplier
    }

    public var isAutomated: Bool { !damagePerSecond.isZero }

    public func scaled(by multiplier: Double) -> StrikePower {
        guard multiplier.isFinite, multiplier > 1 else { return self }
        return StrikePower(
            tapDamage: tapDamage * multiplier,
            damagePerSecond: damagePerSecond * multiplier,
            criticalChance: criticalChance,
            criticalMultiplier: criticalMultiplier,
            criticalDamageMultiplier: criticalDamageMultiplier,
            oreMultiplier: oreMultiplier
        )
    }
}

public struct TapOutcome: Equatable, Sendable {
    public let damage: BigNumber
    public let wasCritical: Bool
    public let hitWeakPoint: Bool
    public let impact: ImpactMeter

    public init(damage: BigNumber, wasCritical: Bool, hitWeakPoint: Bool, impact: ImpactMeter) {
        self.damage = damage
        self.wasCritical = wasCritical
        self.hitWeakPoint = hitWeakPoint
        self.impact = impact
    }
}

public struct ImpactMeter: Codable, Equatable, Sendable {
    public private(set) var value: Double

    public static let empty = ImpactMeter(value: 0)

    public init(value: Double) {
        self.value = min(Balance.impactMeterMaximum, max(0, value))
    }

    public var fraction: Double {
        guard Balance.impactMeterMaximum > 0 else { return 0 }
        return value / Balance.impactMeterMaximum
    }

    public var damageMultiplier: Double {
        1 + fraction * (Balance.impactFullDamageMultiplier - 1)
    }

    public var isFull: Bool { value >= Balance.impactMeterMaximum }

    public func registeringTap() -> Self {
        ImpactMeter(value: value + Balance.impactPerTap)
    }

    public func decayed(by seconds: TimeInterval) -> Self {
        guard seconds > 0 else { return self }
        return ImpactMeter(value: value - Balance.impactDecayPerSecond * seconds)
    }
}

public enum StrikeEngine {
    public static func power(
        equipment: EquipmentLevels,
        permanent: PermanentUpgradeLevels,
        modifications: EquipmentModifications = .empty,
        refinement: RefinementTiers = .none,
        prestigeMultiplier: Double = 1
    ) -> StrikePower {
        let safeMultiplier = prestigeMultiplier.isFinite && prestigeMultiplier > 0
            ? prestigeMultiplier
            : 1

        let tap = BigNumber(Balance.baseTapDamage)
            * BigNumber(Balance.drillRewardGrowthRate)
                .raised(to: Double(Balance.levelsAboveBase(equipment.drill)))
            * RefinementEngine.multiplier(for: .drill, in: refinement)
            * (modifications.drill == .drillImpact
                ? Balance.impactModificationDamageMultiplier
                : 1)
            * safeMultiplier

        let cartSteps = Balance.levelsAboveBase(equipment.cart)
        let automation = cartSteps <= 0
            ? BigNumber.zero
            : BigNumber(Balance.automationDamagePerLevel * Double(cartSteps))
                * BigNumber(Balance.automationGrowthRate).raised(to: Double(cartSteps))
                * RefinementEngine.multiplier(for: .cart, in: refinement)
                * (modifications.cart == .cartFleet
                    ? Balance.fleetModificationAutomationMultiplier
                    : 1)
                * safeMultiplier

        let lampSteps = Balance.levelsAboveBase(equipment.lamp)
        let chance = min(
            Balance.maximumCriticalChance,
            Balance.baseCriticalChance
                + Double(lampSteps) * Balance.lampCriticalChanceIncreasePerLevel
                + (modifications.lamp == .lampFortune
                    ? Balance.fortuneModificationCriticalChance
                    : 0)
        )
        let refinementCritical = BigNumber(Balance.refinementDamageMultiplier)
            .raised(to: Double(refinement.tier(for: .lamp)) * 0.5)
        let additiveCritical = Double(lampSteps) * Balance.lampCriticalMultiplierIncreasePerLevel
            + Double(max(0, permanent.resonanceDetection))
                * Balance.lampCriticalMultiplierIncreasePerLevel
        let criticalBig = BigNumber(Balance.baseCriticalMultiplier)
            * refinementCritical
            + additiveCritical
        let criticalDisplay = criticalBig.doubleValue

        return StrikePower(
            tapDamage: tap,
            damagePerSecond: automation,
            criticalChance: chance,
            criticalMultiplier: criticalDisplay,
            criticalDamageMultiplier: criticalBig,
            oreMultiplier: modifications.cart == .cartFreight
                ? Balance.freightModificationOreMultiplier
                : 1
        )
    }

    public static func tap<R: RandomNumberGenerator>(
        power: StrikePower,
        impact: ImpactMeter,
        hitWeakPoint: Bool,
        weakPointMultiplier: Double,
        using generator: inout R
    ) -> TapOutcome {
        let roll = Double.random(in: 0..<1, using: &generator)
        let critical = roll < power.criticalChance

        var damage = power.tapDamage * impact.damageMultiplier
        if critical { damage *= power.criticalDamageMultiplier }
        if hitWeakPoint { damage *= max(1, weakPointMultiplier) }

        return TapOutcome(
            damage: damage,
            wasCritical: critical,
            hitWeakPoint: hitWeakPoint,
            impact: impact.registeringTap()
        )
    }

    public static func automationDamage(
        power: StrikePower,
        seconds: TimeInterval
    ) -> BigNumber {
        guard seconds > 0, seconds.isFinite, !power.damagePerSecond.isZero else {
            return .zero
        }
        return power.damagePerSecond * seconds
    }
}
