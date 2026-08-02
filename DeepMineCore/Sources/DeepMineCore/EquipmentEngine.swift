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
    /// Purchase results are an economy boundary. Keeping the exact values here prevents
    /// a successful late-game purchase from being reported as `Double.greatestFiniteMagnitude`.
    case purchased(equipment: EquipmentKind, newLevel: Int, cost: BigNumber)
    case insufficientOre(required: BigNumber, available: BigNumber)
    case maximumLevel
    case depthLocked(unlockedLevel: Int, requiredDepthMeters: Int)
    case duplicate
    case invalidLevel
}

public struct UpgradeQuote: Codable, Equatable, Sendable {
    public let equipment: EquipmentKind
    public let currentLevel: Int
    public let cost: Double
    public let bigCost: BigNumber
    public let isRemembered: Bool

    public init(
        equipment: EquipmentKind,
        currentLevel: Int,
        cost: Double,
        bigCost: BigNumber? = nil,
        isRemembered: Bool
    ) {
        self.equipment = equipment
        self.currentLevel = currentLevel
        self.cost = cost
        self.bigCost = bigCost ?? BigNumber(cost)
        self.isRemembered = isRemembered
    }
}

public struct UpgradeRecommendation: Codable, Equatable, Sendable {
    public let equipment: EquipmentKind
    public let currentLevel: Int
    public let nextLevel: Int
    public let cost: Double
    /// Canonical cost for comparisons and player-facing notation. `cost` remains as a
    /// source-compatible legacy projection for older callers, but may saturate above 1e308.
    public let bigCost: BigNumber
    public let marginalExpectedOre: Double
    public let efficiency: Double
    public let isRemembered: Bool

    public init(
        equipment: EquipmentKind,
        currentLevel: Int,
        nextLevel: Int,
        cost: Double,
        bigCost: BigNumber? = nil,
        marginalExpectedOre: Double,
        efficiency: Double,
        isRemembered: Bool = false
    ) {
        self.equipment = equipment
        self.currentLevel = currentLevel
        self.nextLevel = nextLevel
        self.cost = cost
        self.bigCost = bigCost ?? BigNumber(cost)
        self.marginalExpectedOre = marginalExpectedOre
        self.efficiency = efficiency
        self.isRemembered = isRemembered
    }

    private enum CodingKeys: String, CodingKey {
        case equipment
        case currentLevel
        case nextLevel
        case cost
        case bigCost
        case marginalExpectedOre
        case efficiency
        case isRemembered
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyCost = try container.decode(Double.self, forKey: .cost)
        self.init(
            equipment: try container.decode(EquipmentKind.self, forKey: .equipment),
            currentLevel: try container.decode(Int.self, forKey: .currentLevel),
            nextLevel: try container.decode(Int.self, forKey: .nextLevel),
            cost: legacyCost,
            bigCost: try container.decodeIfPresent(BigNumber.self, forKey: .bigCost)
                ?? BigNumber(legacyCost),
            marginalExpectedOre: try container.decode(Double.self, forKey: .marginalExpectedOre),
            efficiency: try container.decode(Double.self, forKey: .efficiency),
            isRemembered: try container.decodeIfPresent(Bool.self, forKey: .isRemembered) ?? false
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(nextLevel, forKey: .nextLevel)
        try container.encode(cost, forKey: .cost)
        try container.encode(bigCost, forKey: .bigCost)
        try container.encode(marginalExpectedOre, forKey: .marginalExpectedOre)
        try container.encode(efficiency, forKey: .efficiency)
        try container.encode(isRemembered, forKey: .isRemembered)
    }
}

public enum EquipmentEngine {
    public static func visualTier(level: Int) -> Int {
        switch max(Balance.minimumEquipmentLevel, level) {
        case ...4: 1
        case ...14: 2
        default: 3
        }
    }

    public static func level(of equipment: EquipmentKind, in levels: EquipmentLevels) -> Int {
        switch equipment {
        case .drill: levels.drill
        case .cart: levels.cart
        case .lamp: levels.lamp
        }
    }

    public static func upgradeCostBig(
        for equipment: EquipmentKind,
        currentLevel: Int,
        rememberedLevel: Int = Balance.minimumEquipmentLevel
    ) -> BigNumber? {
        guard currentLevel >= Balance.minimumEquipmentLevel,
              currentLevel < Balance.equipmentLevelArithmeticBound else { return nil }
        var value = BigNumber(Balance.equipmentBasePrice(for: equipment))
            * BigNumber(Balance.equipmentPriceGrowthRate)
                .raised(to: Double(currentLevel - Balance.minimumEquipmentLevel))
        if currentLevel < rememberedLevel {
            value *= Balance.rememberedRebuyDiscount
        }
        return roundedPrice(value)
    }

    public static func upgradeCost(
        for equipment: EquipmentKind,
        currentLevel: Int,
        rememberedLevel: Int = Balance.minimumEquipmentLevel
    ) -> Double? {
        upgradeCostBig(
            for: equipment,
            currentLevel: currentLevel,
            rememberedLevel: rememberedLevel
        )?.doubleValue
    }

    public static func quote(
        for equipment: EquipmentKind,
        in state: PlayerState
    ) -> UpgradeQuote? {
        let currentLevel = level(of: equipment, in: state.equipment)
        let remembered = level(of: equipment, in: state.rememberedEquipment)
        guard let bigCost = upgradeCostBig(
            for: equipment,
            currentLevel: currentLevel,
            rememberedLevel: remembered
        ) else { return nil }
        return UpgradeQuote(
            equipment: equipment,
            currentLevel: currentLevel,
            cost: bigCost.doubleValue,
            bigCost: bigCost,
            isRemembered: currentLevel < remembered
        )
    }

    public static func unlockedMaximumLevel(in state: PlayerState) -> Int {
        state.unlockedEquipmentLevel
    }

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
        guard currentLevel < Balance.equipmentLevelArithmeticBound else { return .maximumLevel }
        let unlocked = unlockedMaximumLevel(in: state)
        guard currentLevel < unlocked else {
            return .depthLocked(
                unlockedLevel: unlocked,
                requiredDepthMeters: requiredDepth(forLevel: currentLevel + 1)
            )
        }
        let remembered = level(of: command.equipment, in: state.rememberedEquipment)
        guard let cost = upgradeCostBig(
            for: command.equipment,
            currentLevel: currentLevel,
            rememberedLevel: remembered
        ) else { return .invalidLevel }
        guard state.resources.ore >= cost else {
            return .insufficientOre(
                required: cost,
                available: state.resources.ore
            )
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

    private static func roundedPrice(_ value: BigNumber) -> BigNumber {
        guard !value.isZero else { return .zero }
        guard !value.isNegative else { return value }
        if value.exponent < 0 { return .one }
        if value.exponent <= 15 { return BigNumber(ceil(value.doubleValue)) }
        return value
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
