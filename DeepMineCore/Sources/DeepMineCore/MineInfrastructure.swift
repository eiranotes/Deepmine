import Foundation

/// The physical plant a set of equipment levels puts in the passage.
///
/// Upgrades used to be a number on a workbench and a slightly different sprite. Deriving
/// crew, carts, cargo and lighting from the same levels makes a purchase something the
/// player can see installed in the shaft, which is the payoff an idle game's spending loop
/// is built on (D-059).
///
/// One derivation, two surfaces: the app and the web prototype both read these counts, so
/// a rig that looks a certain way on the reference build looks that way in the app.
public struct MineInfrastructure: Equatable, Sendable {
    /// Miners working the face alongside the player's own strikes. Always at least one.
    public let crew: Int
    /// Carts running the rail. Zero until the first cart upgrade, which is the moment the
    /// mine starts moving without input.
    public let carts: Int
    /// Load slots per cart.
    public let cargoSlots: Int
    /// Fixed lamps along the passage. Always at least one, or the shaft is unreadable.
    public let serviceLamps: Int

    public init(crew: Int, carts: Int, cargoSlots: Int, serviceLamps: Int) {
        self.crew = crew
        self.carts = carts
        self.cargoSlots = cargoSlots
        self.serviceLamps = serviceLamps
    }

    /// The secondary readout for structural growth. Deliberately derived from crew rather
    /// than stored, so it can never disagree with what is drawn.
    public var tier: Int { crew }
}

public enum MineInfrastructureEngine {
    public static func infrastructure(
        equipment: EquipmentLevels,
        modifications: EquipmentModifications = .empty
    ) -> MineInfrastructure {
        MineInfrastructure(
            crew: crew(for: equipment),
            carts: carts(level: equipment.cart, modification: modifications.cart),
            cargoSlots: cargoSlots(level: equipment.cart, modification: modifications.cart),
            serviceLamps: serviceLamps(level: equipment.lamp, modification: modifications.lamp)
        )
    }

    /// Crew follows total investment rather than any single tool: the deck fills up as the
    /// whole operation grows, so no one upgrade path leaves the passage empty.
    public static func crew(for equipment: EquipmentLevels) -> Int {
        let total = clampedLevel(equipment.drill)
            + clampedLevel(equipment.cart)
            + clampedLevel(equipment.lamp)
        return min(
            Balance.maximumSupportCrew,
            max(1, total - Balance.supportCrewLevelOffset)
        )
    }

    public static func carts(
        level: Int,
        modification: EquipmentModificationKind?
    ) -> Int {
        let level = clampedLevel(level)
        guard level > Balance.minimumEquipmentLevel else { return 0 }
        let earned = 1
            + (level - Balance.minimumEquipmentLevel - 1) / Balance.cartGrowthLevelStep
        return min(
            Balance.maximumCarts,
            earned + (modification == .cartFleet ? 1 : 0)
        )
    }

    public static func cargoSlots(
        level: Int,
        modification: EquipmentModificationKind?
    ) -> Int {
        let level = clampedLevel(level)
        guard level > Balance.minimumEquipmentLevel else { return 0 }
        let earned = 1
            + (level - Balance.minimumEquipmentLevel - 1) / Balance.cartGrowthLevelStep
        return min(
            Balance.maximumCargoSlots,
            earned + (modification == .cartFreight ? 1 : 0)
        )
    }

    public static func serviceLamps(
        level: Int,
        modification: EquipmentModificationKind?
    ) -> Int {
        min(
            Balance.maximumServiceLamps,
            max(1, clampedLevel(level)) + (modification == .lampReach ? 1 : 0)
        )
    }

    private static func clampedLevel(_ level: Int) -> Int {
        min(Balance.maximumEquipmentLevel, max(Balance.minimumEquipmentLevel, level))
    }
}
