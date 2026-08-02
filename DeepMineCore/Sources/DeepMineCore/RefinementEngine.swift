import Foundation

public struct RefinementTiers: Codable, Equatable, Sendable {
    public var drill: Int
    public var cart: Int
    public var lamp: Int

    public init(drill: Int = 0, cart: Int = 0, lamp: Int = 0) {
        self.drill = drill
        self.cart = cart
        self.lamp = lamp
    }

    public static let none = RefinementTiers()

    public func tier(for equipment: EquipmentKind) -> Int {
        switch equipment {
        case .drill: max(0, drill)
        case .cart: max(0, cart)
        case .lamp: max(0, lamp)
        }
    }

    public var total: Int { max(0, drill) + max(0, cart) + max(0, lamp) }
}

public struct RefinementPurchaseCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let equipment: EquipmentKind

    public init(id: UUID, equipment: EquipmentKind) {
        self.id = id
        self.equipment = equipment
    }
}

public enum RefinementPurchaseResult: Equatable, Sendable {
    case refined(equipment: EquipmentKind, newTier: Int, cost: BigNumber)
    case locked(requiredLevel: Int)
    case insufficientOre(required: BigNumber, available: BigNumber)
    case duplicate
}

public enum RefinementEngine {
    public static func unlockedTiers(forLevel level: Int) -> Int {
        let clamped = max(Balance.minimumEquipmentLevel, level)
        return (clamped - Balance.minimumEquipmentLevel) / Balance.refinementLevelInterval
    }

    public static func requiredLevel(forTier tier: Int) -> Int {
        Balance.minimumEquipmentLevel + max(1, tier) * Balance.refinementLevelInterval
    }

    public static func oreCostBig(for equipment: EquipmentKind, tier: Int) -> BigNumber {
        let unlockLevel = requiredLevel(forTier: tier)
        guard let levelCost = EquipmentEngine.upgradeCostBig(
            for: equipment,
            currentLevel: unlockLevel
        ) else {
            return BigNumber(mantissa: 1, exponent: 1_000_000_000)
        }
        return levelCost * Balance.refinementCostMultiplier
    }

    public static func oreCost(for equipment: EquipmentKind, tier: Int) -> Double {
        oreCostBig(for: equipment, tier: tier).doubleValue
    }

    public static func multiplier(forTier tier: Int) -> BigNumber {
        guard tier > 0 else { return .one }
        return BigNumber(Balance.refinementDamageMultiplier).raised(to: Double(tier))
    }

    public static func multiplier(
        for equipment: EquipmentKind,
        in tiers: RefinementTiers
    ) -> BigNumber {
        multiplier(forTier: tiers.tier(for: equipment))
    }

    public static func purchase(
        _ command: RefinementPurchaseCommand,
        in state: inout PlayerState
    ) -> RefinementPurchaseResult {
        guard !state.appliedPurchaseIDs.contains(command.id) else { return .duplicate }
        let result = purchase(command.equipment, in: &state)
        if case .refined = result { state.appliedPurchaseIDs.insert(command.id) }
        return result
    }

    public static func purchase(
        _ equipment: EquipmentKind,
        in state: inout PlayerState
    ) -> RefinementPurchaseResult {
        let level = EquipmentEngine.level(of: equipment, in: state.equipment)
        let current = state.refinementTiers.tier(for: equipment)
        let unlocked = unlockedTiers(forLevel: level)

        guard current < unlocked else {
            return .locked(requiredLevel: requiredLevel(forTier: current + 1))
        }

        let cost = oreCostBig(for: equipment, tier: current + 1)
        guard state.resources.ore >= cost else {
            return .insufficientOre(
                required: cost,
                available: state.resources.ore
            )
        }

        state.resources.ore -= cost
        switch equipment {
        case .drill: state.refinementTiers.drill = current + 1
        case .cart: state.refinementTiers.cart = current + 1
        case .lamp: state.refinementTiers.lamp = current + 1
        }
        return .refined(
            equipment: equipment,
            newTier: current + 1,
            cost: cost
        )
    }
}
