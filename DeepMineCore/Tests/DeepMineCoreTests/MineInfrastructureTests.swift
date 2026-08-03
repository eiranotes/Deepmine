import XCTest
@testable import DeepMineCore

final class MineInfrastructureTests: XCTestCase {
    private func levels(_ drill: Int, _ cart: Int, _ lamp: Int) -> EquipmentLevels {
        EquipmentLevels(drill: drill, cart: cart, lamp: lamp)
    }

    /// A fresh mine is one miner, no carts, one lamp. Anything more would show a rig the
    /// player has not bought.
    func testAFreshMineHasOneMinerNoCartsAndOneLamp() {
        let plant = MineInfrastructureEngine.infrastructure(equipment: levels(1, 1, 1))
        XCTAssertEqual(plant.crew, 1)
        XCTAssertEqual(plant.carts, 0)
        XCTAssertEqual(plant.cargoSlots, 0)
        XCTAssertEqual(plant.serviceLamps, 1)
        XCTAssertEqual(plant.tier, 1)
        XCTAssertEqual(plant.drillTier, 1)
        XCTAssertNil(plant.drillBranchModule)
        XCTAssertEqual(plant.railLanes, 0)
    }

    /// The first cart upgrade is the beat where the mine starts running on its own, so it
    /// is also the first cart on the rail.
    func testTheFirstCartUpgradePutsACartOnTheRail() {
        XCTAssertEqual(MineInfrastructureEngine.carts(level: 1, modification: nil), 0)
        XCTAssertEqual(MineInfrastructureEngine.carts(level: 2, modification: nil), 1)
        XCTAssertEqual(MineInfrastructureEngine.cargoSlots(level: 2, modification: nil), 1)
    }

    func testCartsAndCargoGrowEveryTwoLevelsAndStopAtTheirCeilings() {
        XCTAssertEqual(MineInfrastructureEngine.carts(level: 4, modification: nil), 2)
        XCTAssertEqual(MineInfrastructureEngine.carts(level: 6, modification: nil), 3)
        XCTAssertEqual(MineInfrastructureEngine.carts(level: 8, modification: nil), 4)
        XCTAssertEqual(MineInfrastructureEngine.carts(level: 40, modification: nil), Balance.maximumCarts)
        XCTAssertEqual(
            MineInfrastructureEngine.cargoSlots(level: 40, modification: nil),
            Balance.maximumCargoSlots
        )
    }

    func testBranchesAddExactlyOneOfTheirOwnKind() {
        XCTAssertEqual(
            MineInfrastructureEngine.carts(level: 4, modification: .cartFleet),
            MineInfrastructureEngine.carts(level: 4, modification: nil) + 1
        )
        XCTAssertEqual(
            MineInfrastructureEngine.cargoSlots(level: 4, modification: .cartFreight),
            MineInfrastructureEngine.cargoSlots(level: 4, modification: nil) + 1
        )
        XCTAssertEqual(
            MineInfrastructureEngine.serviceLamps(level: 2, modification: .lampReach),
            MineInfrastructureEngine.serviceLamps(level: 2, modification: nil) + 1
        )
        // A branch on one tool never changes another tool's plant.
        XCTAssertEqual(
            MineInfrastructureEngine.carts(level: 4, modification: .cartFreight),
            MineInfrastructureEngine.carts(level: 4, modification: nil)
        )
    }

    func testEveryBranchInstallsAnExplicitSceneModule() {
        for modification in EquipmentModificationKind.allCases {
            let plant = MineInfrastructureEngine.infrastructure(
                equipment: levels(5, 5, 5),
                modifications: EquipmentModifications(
                    drill: modification.equipment == .drill ? modification : nil,
                    cart: modification.equipment == .cart ? modification : nil,
                    lamp: modification.equipment == .lamp ? modification : nil
                )
            )
            XCTAssertEqual(
                [plant.drillBranchModule, plant.cartBranchModule, plant.lampBranchModule]
                    .compactMap { $0 },
                [modification]
            )
        }
        let fleet = MineInfrastructureEngine.infrastructure(
            equipment: levels(5, 5, 5),
            modifications: EquipmentModifications(cart: .cartFleet)
        )
        XCTAssertEqual(fleet.railLanes, 2)
    }

    func testLevelsSwapTheMountedDrillAndRefinementAddsVisibleBands() {
        XCTAssertEqual(
            MineInfrastructureEngine.infrastructure(equipment: levels(1, 1, 1)).drillTier,
            1
        )
        XCTAssertEqual(
            MineInfrastructureEngine.infrastructure(equipment: levels(2, 1, 1)).drillTier,
            2
        )
        XCTAssertEqual(
            MineInfrastructureEngine.infrastructure(equipment: levels(5, 1, 1)).drillTier,
            3
        )
        let refined = MineInfrastructureEngine.infrastructure(
            equipment: levels(15, 15, 15),
            refinements: RefinementTiers(drill: 2, cart: 4, lamp: 1)
        )
        XCTAssertEqual(refined.drillRefinementBands, 2)
        XCTAssertEqual(refined.cartRefinementBands, Balance.maximumVisibleRefinementBands)
        XCTAssertEqual(refined.lampRefinementBands, 1)
        XCTAssertEqual(refined.drillVisual.refinementTier, 2)
        XCTAssertEqual(refined.cartVisual.refinementTier, 4)
    }

    func testEveryEquipmentLevelChangesItsPhysicalToolState() {
        var previous = MineInfrastructureEngine.visualState(level: 1)
        for level in 2...40 {
            let current = MineInfrastructureEngine.visualState(level: level)
            XCTAssertNotEqual(current, previous, "level \(level) must change the rig")
            XCTAssertTrue(
                current.upgradeCells != previous.upgradeCells
                    || current.generation != previous.generation
                    || current.housingVariant != previous.housingVariant
                    || current.artTier != previous.artTier,
                "level \(level) needs a physical delta"
            )
            if current.generation != previous.generation {
                XCTAssertNotEqual(
                    current.housingVariant,
                    previous.housingVariant,
                    "generation \(current.generation) must replace the housing silhouette"
                )
            }
            XCTAssertEqual(current.level, level)
            previous = current
        }
    }

    func testEveryRefinementKeepsItsExactPhysicalPlatePastThreeBands() {
        for tier in 1...12 {
            let visual = MineInfrastructureEngine.visualState(level: 80, refinementTier: tier)
            XCTAssertEqual(visual.refinementTier, tier)
            XCTAssertEqual(
                visual.refinementBands,
                min(tier, Balance.maximumVisibleRefinementBands)
            )
        }
    }

    func testCrewFollowsTotalInvestmentSoNoSinglePathLeavesThePassageEmpty() {
        XCTAssertEqual(MineInfrastructureEngine.crew(for: levels(1, 1, 1)), 1)
        XCTAssertEqual(MineInfrastructureEngine.crew(for: levels(5, 4, 3)), 2)
        XCTAssertEqual(MineInfrastructureEngine.crew(for: levels(6, 5, 3)), 4)
        XCTAssertEqual(
            MineInfrastructureEngine.crew(for: levels(60, 60, 60)),
            Balance.maximumSupportCrew
        )
    }

    /// Every count has to stay inside what the scene can draw, at any level the ladder
    /// allows and below it.
    func testEveryCountStaysWithinItsDrawableRange() {
        for level in [-5, 0, 1, 2, 7, 15, 60, 200, 5_000] {
            let plant = MineInfrastructureEngine.infrastructure(
                equipment: levels(level, level, level),
                modifications: EquipmentModifications(
                    drill: .drillWide,
                    cart: .cartFleet,
                    lamp: .lampReach
                )
            )
            XCTAssertTrue((1...Balance.maximumSupportCrew).contains(plant.crew), "\(level)")
            XCTAssertTrue((0...Balance.maximumCarts).contains(plant.carts), "\(level)")
            XCTAssertTrue((0...Balance.maximumCargoSlots).contains(plant.cargoSlots), "\(level)")
            XCTAssertTrue(
                (1...Balance.maximumServiceLamps).contains(plant.serviceLamps),
                "\(level)"
            )
        }
    }

    /// Buying anything must never remove plant that was already installed.
    func testPlantNeverShrinksAsLevelsRise() {
        var previous = MineInfrastructureEngine.infrastructure(equipment: levels(1, 1, 1))
        for level in 2...40 {
            let plant = MineInfrastructureEngine.infrastructure(
                equipment: levels(level, level, level)
            )
            XCTAssertGreaterThanOrEqual(plant.crew, previous.crew, "level \(level)")
            XCTAssertGreaterThanOrEqual(plant.carts, previous.carts, "level \(level)")
            XCTAssertGreaterThanOrEqual(plant.cargoSlots, previous.cargoSlots, "level \(level)")
            XCTAssertGreaterThanOrEqual(plant.serviceLamps, previous.serviceLamps, "level \(level)")
            previous = plant
        }
    }
}
