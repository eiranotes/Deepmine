import XCTest
@testable import DeepMineCore

/// The wallet used to be a `Double`, and that was defensible while the curve converged:
/// ore saturated at 41,881m, seven times deeper than a 180-day heavy persona reached.
///
/// Removing the level ceiling and adding refinement changed the shape. The descent now
/// accelerates instead of slowing, and the simulation runs past 58,000m — where a `Double`
/// wallet is `inf` and every price comparison against it is meaningless. These tests pin
/// the property the migration was for: the wallet has no ceiling to hit (D-069).
final class OreCapacityTests: XCTestCase {
    /// The depth a `Double` wallet used to die at. Nothing here may break at it.
    private let formerSaturationDepth = 41_881

    func testTheWalletHoldsOreFarPastTheOldDoubleCeiling() throws {
        let segment = formerSaturationDepth / Balance.metersPerSegment
        let yield = RockGenerator.segment(at: segment * 2).oreYield

        XCTAssertGreaterThan(yield, .zero)
        // `doubleValue` saturates at the Double ceiling by design, which is exactly the
        // information a Double wallet would have lost. The BigNumber still knows the
        // magnitude.
        XCTAssertEqual(yield.doubleValue, .greatestFiniteMagnitude)
        let magnitude = try XCTUnwrap(yield.log10Value)
        XCTAssertGreaterThan(magnitude, 308)
    }

    func testAccumulatingPastTheOldCeilingStaysExact() {
        var wallet = BigNumber.zero
        let deep = RockGenerator.segment(at: 20_000).oreYield
        for _ in 0..<10 { wallet += deep }

        XCTAssertGreaterThan(wallet, deep)
        // Ten of the same value is exactly ten times it — no saturation, no clamp.
        XCTAssertEqual((wallet / deep).doubleValue, 10, accuracy: 0.0001)
    }

    /// The guard `MiningLoop` used to need is gone. A strike's ore must land in full.
    func testEveryStrikeCreditsItsFullOre() {
        var state = PlayerState()
        state.equipment = EquipmentLevels(drill: 1, cart: 60, lamp: 1)
        state.resources.ore = RockGenerator.segment(at: 12_000).oreYield
        let before = state.resources.ore

        let update = MiningLoop.advance(seconds: 60, in: &state)

        XCTAssertGreaterThan(update.oreGained, .zero)
        XCTAssertEqual(state.resources.ore, before + update.oreGained)
    }

    /// Prices are still ordinary numbers, so a very rich wallet must still buy correctly
    /// rather than comparing a finite cost against an unrepresentable balance.
    func testPurchasesResolveAgainstAnEnormousBalance() {
        var state = PlayerState()
        state.resources.ore = RockGenerator.segment(at: 15_000).oreYield

        let command = UpgradePurchaseCommand(id: UUID(), equipment: .drill)
        guard case .purchased = EquipmentEngine.purchase(command, in: &state) else {
            return XCTFail("a wallet past the old ceiling should still afford a level")
        }
        XCTAssertEqual(state.equipment.drill, 2)
        XCTAssertGreaterThan(state.resources.ore, .zero)
    }

    /// Relative precision is what a clicker actually needs, and the mantissa keeps it at
    /// any magnitude.
    func testRelativePrecisionHoldsAtEveryDepth() {
        for segment in stride(from: 250, through: 20_000, by: 4_000) {
            let yield = RockGenerator.segment(at: segment).oreYield
            let stepped = yield + BigNumber(1)
            // Adding one to a huge number cannot be represented, and must not corrupt it.
            XCTAssertGreaterThanOrEqual(stepped, yield, "segment \(segment)")
        }
    }
}
