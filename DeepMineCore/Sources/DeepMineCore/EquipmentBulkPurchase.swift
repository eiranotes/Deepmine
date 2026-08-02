import Foundation

public struct BulkUpgradePurchaseCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let equipment: EquipmentKind
    public let maximumPurchases: Int?
    public let stopAtRememberedLevel: Bool

    public init(
        id: UUID,
        equipment: EquipmentKind,
        maximumPurchases: Int? = nil,
        stopAtRememberedLevel: Bool = false
    ) {
        self.id = id
        self.equipment = equipment
        self.maximumPurchases = maximumPurchases
        self.stopAtRememberedLevel = stopAtRememberedLevel
    }
}

public enum BulkUpgradePurchaseResult: Codable, Equatable, Sendable {
    case purchased(
        equipment: EquipmentKind,
        newLevel: Int,
        levelsBought: Int,
        totalCost: BigNumber
    )
    case nothingAffordable
    case depthLocked(unlockedLevel: Int, requiredDepthMeters: Int)
    case duplicate
    case invalidLevel
}

extension EquipmentEngine {
    public static func purchaseBulk(
        _ command: BulkUpgradePurchaseCommand,
        in state: inout PlayerState
    ) -> BulkUpgradePurchaseResult {
        guard !state.appliedPurchaseIDs.contains(command.id) else { return .duplicate }
        let limit = max(1, command.maximumPurchases ?? 100_000)
        let remembered = level(of: command.equipment, in: state.rememberedEquipment)
        var bought = 0
        var total = BigNumber.zero

        while bought < limit {
            let current = level(of: command.equipment, in: state.equipment)
            if command.stopAtRememberedLevel, current >= remembered { break }
            guard current >= Balance.minimumEquipmentLevel else { return .invalidLevel }
            let unlocked = unlockedMaximumLevel(in: state)
            guard current < unlocked else {
                if bought == 0 {
                    return .depthLocked(
                        unlockedLevel: unlocked,
                        requiredDepthMeters: requiredDepth(forLevel: current + 1)
                    )
                }
                break
            }
            guard let quote = quote(for: command.equipment, in: state),
                  state.resources.ore >= quote.bigCost else { break }
            state.resources.ore -= quote.bigCost
            total += quote.bigCost
            let next = current + 1
            setBulkLevel(next, for: command.equipment, in: &state.equipment)
            if next > remembered {
                setBulkLevel(next, for: command.equipment, in: &state.rememberedEquipment)
            }
            bought += 1
        }

        guard bought > 0 else { return .nothingAffordable }
        state.appliedPurchaseIDs.insert(command.id)
        return .purchased(
            equipment: command.equipment,
            newLevel: level(of: command.equipment, in: state.equipment),
            levelsBought: bought,
            totalCost: total
        )
    }

    private static func setBulkLevel(
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
