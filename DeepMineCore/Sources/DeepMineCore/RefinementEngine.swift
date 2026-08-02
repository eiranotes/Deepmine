import Foundation

/// Refinement tiers, per equipment.
///
/// Stored rather than derived, because a tier is bought: the level unlocks the option and
/// ore pays for it. Two players at the same level can have different rigs.
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

/// A user-originated refinement purchase. Its receipt shares the global purchase ID set
/// with ordinary equipment purchases, so retries cannot buy the same tier twice.
public struct RefinementPurchaseCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let equipment: EquipmentKind

    public init(id: UUID, equipment: EquipmentKind) {
        self.id = id
        self.equipment = equipment
    }
}

public enum RefinementPurchaseResult: Equatable, Sendable {
    case refined(equipment: EquipmentKind, newTier: Int, cost: Double)
    /// The level has not reached the next tier's unlock yet.
    case locked(requiredLevel: Int)
    case insufficientOre(required: Double, available: Double)
    case duplicate
}

/// The multiplicative axis that carries growth past the level ladder.
///
/// The ladder is deliberately gentle — D-044 tuned it so that early depth reads as
/// tightening rather than as a wall — and a gentle ladder cannot outpace compounding
/// integrity on its own. Refinement multiplies on top of it, arriving in visible steps
/// rather than as a fraction of a percent per purchase.
public enum RefinementEngine {
    /// Tiers a level entitles the player to buy. Buying is still explicit.
    public static func unlockedTiers(forLevel level: Int) -> Int {
        let clamped = max(Balance.minimumEquipmentLevel, level)
        return (clamped - Balance.minimumEquipmentLevel) / Balance.refinementLevelInterval
    }

    /// Level at which the given tier becomes purchasable.
    public static func requiredLevel(forTier tier: Int) -> Int {
        Balance.minimumEquipmentLevel + max(1, tier) * Balance.refinementLevelInterval
    }

    /// Ore for the next tier, priced off the level that unlocks it so the cost rides the
    /// same curve the ladder does.
    public static func oreCost(for equipment: EquipmentKind, tier: Int) -> Double {
        let unlockLevel = requiredLevel(forTier: tier)
        let levelCost = EquipmentEngine.upgradeCost(
            for: equipment,
            currentLevel: unlockLevel
        ) ?? Double.greatestFiniteMagnitude
        let scaled = levelCost * Balance.refinementCostMultiplier
        return scaled.isFinite ? ceil(scaled) : Double.greatestFiniteMagnitude
    }

    /// Damage multiplier a tier count contributes.
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

    /// Idempotent app/write-path purchase. Failed or locked attempts do not consume the ID;
    /// only a committed economic mutation becomes a replayable receipt.
    public static func purchase(
        _ command: RefinementPurchaseCommand,
        in state: inout PlayerState
    ) -> RefinementPurchaseResult {
        guard !state.appliedPurchaseIDs.contains(command.id) else { return .duplicate }
        let result = purchase(command.equipment, in: &state)
        if case .refined = result { state.appliedPurchaseIDs.insert(command.id) }
        return result
    }

    /// Pure economy operation used by the deterministic balance simulator and focused Core
    /// tests. User-facing writes must use the command overload above.
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

        let cost = oreCost(for: equipment, tier: current + 1)
        guard state.resources.ore >= cost else {
            return .insufficientOre(required: cost, available: state.resources.ore.doubleValue)
        }

        state.resources.ore -= cost
        switch equipment {
        case .drill: state.refinementTiers.drill = current + 1
        case .cart: state.refinementTiers.cart = current + 1
        case .lamp: state.refinementTiers.lamp = current + 1
        }
        return .refined(equipment: equipment, newTier: current + 1, cost: cost)
    }
}
