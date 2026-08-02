import Foundation

/// One mutually-exclusive change to each tool. A modification lasts for the current
/// run and resets with the equipment at prestige, so the next descent can choose a
/// different build.
public enum EquipmentModificationKind: String, Codable, CaseIterable, Hashable, Sendable {
    case drillWide
    case drillImpact
    case cartFleet
    case cartFreight
    case lampReach
    case lampFortune

    public var equipment: EquipmentKind {
        switch self {
        case .drillWide, .drillImpact: .drill
        case .cartFleet, .cartFreight: .cart
        case .lampReach, .lampFortune: .lamp
        }
    }
}

public struct EquipmentModifications: Codable, Equatable, Sendable {
    public private(set) var drill: EquipmentModificationKind?
    public private(set) var cart: EquipmentModificationKind?
    public private(set) var lamp: EquipmentModificationKind?

    public static let empty = EquipmentModifications()

    public init(
        drill: EquipmentModificationKind? = nil,
        cart: EquipmentModificationKind? = nil,
        lamp: EquipmentModificationKind? = nil
    ) {
        self.drill = drill?.equipment == .drill ? drill : nil
        self.cart = cart?.equipment == .cart ? cart : nil
        self.lamp = lamp?.equipment == .lamp ? lamp : nil
    }

    public func selected(for equipment: EquipmentKind) -> EquipmentModificationKind? {
        switch equipment {
        case .drill: drill
        case .cart: cart
        case .lamp: lamp
        }
    }

    mutating func select(_ modification: EquipmentModificationKind) {
        switch modification.equipment {
        case .drill: drill = modification
        case .cart: cart = modification
        case .lamp: lamp = modification
        }
    }
}

public struct EquipmentModificationCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let modification: EquipmentModificationKind

    public init(id: UUID, modification: EquipmentModificationKind) {
        self.id = id
        self.modification = modification
    }
}

public enum EquipmentModificationPurchaseResult: Codable, Equatable, Sendable {
    case purchased(modification: EquipmentModificationKind, cost: Double)
    case insufficientOre(required: Double, available: Double)
    case levelLocked(requiredLevel: Int)
    case alreadySelected(EquipmentModificationKind)
    case duplicate
}

public enum EquipmentModificationEngine {
    public static func cost(for equipment: EquipmentKind) -> Double {
        switch equipment {
        case .drill: Balance.drillModificationCost
        case .cart: Balance.cartModificationCost
        case .lamp: Balance.lampModificationCost
        }
    }

    public static func purchase(
        _ command: EquipmentModificationCommand,
        in state: inout PlayerState
    ) -> EquipmentModificationPurchaseResult {
        guard !state.appliedPurchaseIDs.contains(command.id) else { return .duplicate }
        let equipment = command.modification.equipment
        if let selected = state.equipmentModifications.selected(for: equipment) {
            return .alreadySelected(selected)
        }
        guard EquipmentEngine.level(of: equipment, in: state.equipment)
                >= Balance.equipmentModificationUnlockLevel else {
            return .levelLocked(requiredLevel: Balance.equipmentModificationUnlockLevel)
        }
        let cost = cost(for: equipment)
        guard state.resources.ore >= cost else {
            return .insufficientOre(required: cost, available: state.resources.ore.doubleValue)
        }
        state.resources.ore -= cost
        state.equipmentModifications.select(command.modification)
        state.appliedPurchaseIDs.insert(command.id)
        return .purchased(modification: command.modification, cost: cost)
    }

    public static func boreWidth(
        drillLevel: Int,
        modifications: EquipmentModifications
    ) -> Double {
        let levels = Double(Balance.levelsAboveBase(drillLevel))
        let wide = modifications.drill == .drillWide
            ? Balance.wideModificationBoreWidthPoints
            : 0
        return min(
            Balance.boreWidthMaximumPoints,
            Balance.boreWidthBasePoints + levels * Balance.boreWidthPerDrillLevel + wide
        )
    }
}
