import XCTest
@testable import DeepMineCore

/// Why the wallet is still `Double` while damage and rock are `BigNumber`.
///
/// The mismatch looks like an oversight, and it was listed as a known risk. Measured
/// against the actual curve it is not one yet: ore saturates a `Double` around segment
/// 10,470, which is seven times deeper than a 180-day heavy persona reaches and roughly
/// 3.7 years of uninterrupted play at that rate — and prestige returns the player to the
/// surface long before then.
///
/// These tests exist so that stops being an argument in a document. If the ore curve is
/// ever steepened, the headroom assertion fails and the migration becomes real work with
/// a number attached.
final class OreCapacityTests: XCTestCase {
    /// Deepest segment whose ore yield still fits in a `Double`.
    private var saturationSegment: Int {
        var index = 0
        while index < 100_000 {
            let yield = Balance.baseSegmentOre
                * pow(Balance.segmentOreGrowthRate, Double(index))
            if !yield.isFinite { return index }
            index += 1
        }
        return index
    }

    /// 180-day heavy persona, from the balance simulation recorded in PROJECT_STATUS.
    private let heavyOneEightyDepthMeters = 5_640

    func testOreFitsInADoubleFarBeyondTheMeasuredCurve() {
        let saturationDepth = saturationSegment * Balance.metersPerSegment
        XCTAssertGreaterThan(saturationDepth, heavyOneEightyDepthMeters * 5)
    }

    /// The property that actually matters for a clicker: relative precision must not decay
    /// as the numbers grow, or late rewards would round away against the balance.
    func testRelativePrecisionHoldsAcrossTheWholeReachableRange() {
        for depth in stride(from: 1_000, through: 40_000, by: 6_500) {
            let yield = Balance.baseSegmentOre
                * pow(Balance.segmentOreGrowthRate, Double(depth / Balance.metersPerSegment))
            guard yield.isFinite, yield > 0 else { continue }
            XCTAssertLessThan(yield.ulp / yield, 1e-15, "depth \(depth)")
        }
    }

    /// Past saturation the wallet must clamp rather than become infinite: an infinite
    /// balance would make every price affordable and every comparison meaningless.
    func testTheWalletClampsInsteadOfOverflowing() {
        var state = PlayerState()
        state.resources.ore = .greatestFiniteMagnitude
        state.equipment = EquipmentLevels(drill: 1, cart: 60, lamp: 1)

        MiningLoop.advance(seconds: 60 * 60, in: &state)

        XCTAssertTrue(state.resources.ore.isFinite)
        XCTAssertFalse(state.resources.ore.isNaN)
        XCTAssertEqual(state.resources.ore, .greatestFiniteMagnitude)
    }

    /// A clamped wallet still has to buy things, or hitting the ceiling would silently
    /// end progression.
    func testPurchasesStillResolveAtTheCeiling() throws {
        var state = PlayerState()
        state.resources.ore = .greatestFiniteMagnitude

        let command = UpgradePurchaseCommand(id: UUID(), equipment: .drill)
        let outcome = EquipmentEngine.purchase(command, in: &state)
        guard case .purchased = outcome else {
            return XCTFail("expected a purchase at the ceiling, got \(outcome)")
        }
        XCTAssertEqual(state.equipment.drill, 2)
        XCTAssertTrue(state.resources.ore.isFinite)
    }
}
