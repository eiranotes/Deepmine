import Foundation

public enum EquipmentKind: String, Codable, CaseIterable, Hashable, Sendable {
    case drill
    case cart
    case lamp
}

public struct UpgradePurchaseCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let equipment: EquipmentKind

    public init(id: UUID, equipment: EquipmentKind) {
        self.id = id
        self.equipment = equipment
    }
}

public enum UpgradePurchaseResult: Codable, Equatable, Sendable {
    case purchased(equipment: EquipmentKind, newLevel: Int, cost: Double)
    case insufficientOre(required: Double, available: Double)
    case maximumLevel
    case depthLocked(unlockedLevel: Int, requiredDepthMeters: Int)
    case duplicate
    case invalidLevel
}

public struct UpgradeQuote: Codable, Equatable, Sendable {
    public let equipment: EquipmentKind
    public let currentLevel: Int
    public let cost: Double
    public let isRemembered: Bool

    public init(equipment: EquipmentKind, currentLevel: Int, cost: Double, isRemembered: Bool) {
        self.equipment = equipment
        self.currentLevel = currentLevel
        self.cost = cost
        self.isRemembered = isRemembered
    }
}

public struct UpgradeRecommendation: Codable, Equatable, Sendable {
    public let equipment: EquipmentKind
    public let currentLevel: Int
    public let nextLevel: Int
    public let cost: Double
    public let marginalExpectedOre: Double
    public let efficiency: Double
    public let isRemembered: Bool

    public init(
        equipment: EquipmentKind,
        currentLevel: Int,
        nextLevel: Int,
        cost: Double,
        marginalExpectedOre: Double,
        efficiency: Double,
        isRemembered: Bool = false
    ) {
        self.equipment = equipment
        self.currentLevel = currentLevel
        self.nextLevel = nextLevel
        self.cost = cost
        self.marginalExpectedOre = marginalExpectedOre
        self.efficiency = efficiency
        self.isRemembered = isRemembered
    }
}

public enum EquipmentEngine {
    public static func level(of equipment: EquipmentKind, in levels: EquipmentLevels) -> Int {
        switch equipment {
        case .drill: levels.drill
        case .cart: levels.cart
        case .lamp: levels.lamp
        }
    }

    public static func upgradeCost(
        for equipment: EquipmentKind,
        currentLevel: Int,
        rememberedLevel: Int = Balance.minimumEquipmentLevel
    ) -> Double? {
        guard currentLevel >= Balance.minimumEquipmentLevel,
              currentLevel < Balance.maximumEquipmentLevel else { return nil }
        let unrounded = Balance.equipmentBasePrice(for: equipment)
            * Balance.compounded(
                Balance.equipmentPriceGrowthRate,
                currentLevel - Balance.minimumEquipmentLevel
            )
        let discounted = currentLevel < rememberedLevel
            ? unrounded * Balance.rememberedRebuyDiscount
            : unrounded
        return ceil(discounted)
    }

    public static func quote(
        for equipment: EquipmentKind,
        in state: PlayerState
    ) -> UpgradeQuote? {
        let currentLevel = level(of: equipment, in: state.equipment)
        let remembered = level(of: equipment, in: state.rememberedEquipment)
        guard let cost = upgradeCost(
            for: equipment,
            currentLevel: currentLevel,
            rememberedLevel: remembered
        ) else { return nil }
        return UpgradeQuote(
            equipment: equipment,
            currentLevel: currentLevel,
            cost: cost,
            isRemembered: currentLevel < remembered
        )
    }

    public static func unlockedMaximumLevel(in state: PlayerState) -> Int {
        Balance.maximumEquipmentLevel(forDepth: state.depthMeters)
    }

    /// Depth required before `level` becomes purchasable, for the locked-state copy.
    public static func requiredDepth(forLevel level: Int) -> Int {
        max(0, level - Balance.equipmentLevelUnlockBase) * Balance.equipmentLevelUnlockDepthStep
    }

    public static func drillRewardMultiplier(level: Int) -> Double {
        Balance.drillMultiplier(level: level)
    }

    public static func cartLengthMultiplier(length: SessionLength, level: Int) -> Double {
        Balance.lengthMultiplier(for: length) * Balance.cartMultiplier(level: level, length: length)
    }

    public static func lampChanceBonus(level: Int) -> Double {
        Double(Balance.levelsAboveBase(level)) * Balance.lampVeinChanceIncreasePerLevel
    }

    public static func purchase(
        _ command: UpgradePurchaseCommand,
        in state: inout PlayerState
    ) -> UpgradePurchaseResult {
        guard !state.appliedPurchaseIDs.contains(command.id) else { return .duplicate }
        let currentLevel = level(of: command.equipment, in: state.equipment)
        guard currentLevel >= Balance.minimumEquipmentLevel else { return .invalidLevel }
        guard currentLevel < Balance.maximumEquipmentLevel else { return .maximumLevel }
        let unlocked = unlockedMaximumLevel(in: state)
        guard currentLevel < unlocked else {
            return .depthLocked(
                unlockedLevel: unlocked,
                requiredDepthMeters: requiredDepth(forLevel: currentLevel + 1)
            )
        }
        let remembered = level(of: command.equipment, in: state.rememberedEquipment)
        guard let cost = upgradeCost(
            for: command.equipment,
            currentLevel: currentLevel,
            rememberedLevel: remembered
        ) else {
            return .invalidLevel
        }
        guard state.resources.ore >= cost else {
            return .insufficientOre(required: cost, available: state.resources.ore)
        }

        state.resources.ore -= cost
        let newLevel = currentLevel + 1
        setLevel(newLevel, for: command.equipment, in: &state.equipment)
        if newLevel > remembered {
            setLevel(newLevel, for: command.equipment, in: &state.rememberedEquipment)
        }
        state.appliedPurchaseIDs.insert(command.id)
        return .purchased(
            equipment: command.equipment,
            newLevel: newLevel,
            cost: cost
        )
    }

    private static func setLevel(
        _ level: Int,
        for equipment: EquipmentKind,
        in levels: inout EquipmentLevels
    ) {
        switch equipment {
        case .drill: levels.drill = level
        case .cart: levels.cart = level
        case .lamp: levels.lamp = level
        }
    }
}
