import Foundation

/// Persistent physical state for one rig subsystem.
///
/// The art tier communicates major mass changes. `upgradeCells` makes each purchase inside
/// that tier add a service cell, and `generation` advances whenever the four-cell bank is
/// absorbed into the housing. The exact level/refinement plates ensure late-game purchases
/// never collapse back to an unchanged three-sprite state.
public struct RigToolVisualState: Equatable, Sendable {
    public let level: Int
    public let artTier: Int
    public let upgradeCells: Int
    public let generation: Int
    /// One of four authored housing silhouettes. Every generation rollover swaps the
    /// subsystem body instead of only resetting its service cells.
    public let housingVariant: Int
    public let refinementTier: Int
    public let refinementBands: Int

    public init(
        level: Int,
        artTier: Int,
        upgradeCells: Int,
        generation: Int,
        housingVariant: Int,
        refinementTier: Int,
        refinementBands: Int
    ) {
        self.level = level
        self.artTier = artTier
        self.upgradeCells = upgradeCells
        self.generation = generation
        self.housingVariant = housingVariant
        self.refinementTier = refinementTier
        self.refinementBands = refinementBands
    }
}

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
    /// One shared render contract per subsystem. Every level changes either the installed
    /// service-cell bank or the housing generation; every refinement changes its R plate.
    public let drillVisual: RigToolVisualState
    public let cartVisual: RigToolVisualState
    public let lampVisual: RigToolVisualState
    /// Branch modules are explicit pieces of plant, never an invisible percentage.
    public let drillBranchModule: EquipmentModificationKind?
    public let cartBranchModule: EquipmentModificationKind?
    public let lampBranchModule: EquipmentModificationKind?
    /// A fleet branch installs a second rail lane; otherwise a purchased cart uses one.
    public let railLanes: Int

    public var drillTier: Int { drillVisual.artTier }
    public var drillRefinementBands: Int { drillVisual.refinementBands }
    public var cartRefinementBands: Int { cartVisual.refinementBands }
    public var lampRefinementBands: Int { lampVisual.refinementBands }

    public init(
        crew: Int,
        carts: Int,
        cargoSlots: Int,
        serviceLamps: Int,
        drillVisual: RigToolVisualState,
        cartVisual: RigToolVisualState,
        lampVisual: RigToolVisualState,
        drillBranchModule: EquipmentModificationKind?,
        cartBranchModule: EquipmentModificationKind?,
        lampBranchModule: EquipmentModificationKind?,
        railLanes: Int
    ) {
        self.crew = crew
        self.carts = carts
        self.cargoSlots = cargoSlots
        self.serviceLamps = serviceLamps
        self.drillVisual = drillVisual
        self.cartVisual = cartVisual
        self.lampVisual = lampVisual
        self.drillBranchModule = drillBranchModule
        self.cartBranchModule = cartBranchModule
        self.lampBranchModule = lampBranchModule
        self.railLanes = railLanes
    }

    /// The secondary readout for structural growth. Deliberately derived from crew rather
    /// than stored, so it can never disagree with what is drawn.
    public var tier: Int { crew }
}

public enum MineInfrastructureEngine {
    public static func infrastructure(
        equipment: EquipmentLevels,
        modifications: EquipmentModifications = .empty,
        refinements: RefinementTiers = .none
    ) -> MineInfrastructure {
        let carts = carts(level: equipment.cart, modification: modifications.cart)
        return MineInfrastructure(
            crew: crew(for: equipment),
            carts: carts,
            cargoSlots: cargoSlots(level: equipment.cart, modification: modifications.cart),
            serviceLamps: serviceLamps(level: equipment.lamp, modification: modifications.lamp),
            drillVisual: visualState(
                level: equipment.drill,
                refinementTier: refinements.drill
            ),
            cartVisual: visualState(
                level: equipment.cart,
                refinementTier: refinements.cart
            ),
            lampVisual: visualState(
                level: equipment.lamp,
                refinementTier: refinements.lamp
            ),
            drillBranchModule: modifications.drill,
            cartBranchModule: modifications.cart,
            lampBranchModule: modifications.lamp,
            railLanes: carts == 0 ? 0 : (modifications.cart == .cartFleet ? 2 : 1)
        )
    }

    /// A level purchase always changes this tuple. Inside a four-level housing generation
    /// it installs another visible cell; crossing the boundary advances the housing and
    /// clears the absorbed cell bank. The exact plate remains available to renderers.
    public static func visualState(
        level: Int,
        refinementTier: Int = 0
    ) -> RigToolVisualState {
        let level = clampedLevel(level)
        let investment = level - Balance.minimumEquipmentLevel
        let refinementTier = max(0, refinementTier)
        return RigToolVisualState(
            level: level,
            artTier: EquipmentEngine.visualTier(level: level),
            upgradeCells: investment % Balance.rigUpgradeCellsPerGeneration,
            generation: investment / Balance.rigUpgradeCellsPerGeneration,
            housingVariant: investment / Balance.rigUpgradeCellsPerGeneration % 4 + 1,
            refinementTier: refinementTier,
            refinementBands: visibleRefinementBands(refinementTier)
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
        min(Balance.equipmentLevelArithmeticBound, max(Balance.minimumEquipmentLevel, level))
    }

    private static func visibleRefinementBands(_ tier: Int) -> Int {
        min(Balance.maximumVisibleRefinementBands, max(0, tier))
    }
}
