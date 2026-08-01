import XCTest
@testable import DeepMineCore

final class WorkFaceForecastTests: XCTestCase {
    private func player(drill: Int = 1, cart: Int = 1, lamp: Int = 1) -> PlayerState {
        var state = PlayerState()
        state.equipment = EquipmentLevels(drill: drill, cart: cart, lamp: lamp)
        return state
    }

    /// A cart at base level hauls nothing, so there is no honest ETA to show. Printing one
    /// would promise idle income the player has not bought.
    func testNoAutomaticEtaBeforeTheFirstCartUpgrade() {
        let forecast = MiningLoop.forecast(for: player(cart: 1))
        XCTAssertNil(forecast.automaticSecondsToBreak)
        XCTAssertNotNil(forecast.tapsToBreak)
    }

    func testAutomaticEtaAppearsWithTheFirstCartUpgrade() throws {
        let forecast = MiningLoop.forecast(for: player(cart: 2))
        let seconds = try XCTUnwrap(forecast.automaticSecondsToBreak)
        XCTAssertGreaterThan(seconds, 0)
        XCTAssertTrue(seconds.isFinite)
    }

    func testBuyingCartLevelsShortensTheEta() throws {
        let slow = try XCTUnwrap(MiningLoop.forecast(for: player(cart: 2)).automaticSecondsToBreak)
        let fast = try XCTUnwrap(MiningLoop.forecast(for: player(cart: 5)).automaticSecondsToBreak)
        XCTAssertLessThan(fast, slow)
    }

    func testBuyingDrillLevelsReducesTheTapCount() throws {
        let many = try XCTUnwrap(MiningLoop.forecast(for: player(drill: 1)).tapsToBreak)
        let few = try XCTUnwrap(MiningLoop.forecast(for: player(drill: 6)).tapsToBreak)
        XCTAssertLessThan(few, many)
    }

    /// The first rock is ten integrity against one damage: ten taps. If this ever needs
    /// changing, the early game changed with it.
    func testTheFirstRockIsTenTapsAtLevelOne() {
        XCTAssertEqual(MiningLoop.forecast(for: player()).tapsToBreak, 10)
    }

    func testExpectedOreMatchesTheSegmentAndItsFreightModification() {
        var plain = player()
        let base = MiningLoop.forecast(for: plain).expectedOre
        XCTAssertEqual(base, plain.mineFace.segment.oreYield)

        plain.equipment = EquipmentLevels(drill: 1, cart: 6, lamp: 1)
        plain.equipmentModifications = EquipmentModifications(
            drill: nil,
            cart: .cartFreight,
            lamp: nil
        )
        let freighted = MiningLoop.forecast(for: plain).expectedOre
        XCTAssertGreaterThan(freighted, base)
    }

    /// Damage taken so far has to shorten what is left, or the ETA would restate the full
    /// rock after every tap.
    func testRemainingIntegrityAndEtaShrinkAsTheRockIsStruck() throws {
        var state = player(cart: 3)
        let before = MiningLoop.forecast(for: state)
        var generator = SeededGenerator(seed: 42)
        MiningLoop.strike(using: &generator, in: &state)
        let after = MiningLoop.forecast(for: state)

        XCTAssertLessThan(after.remainingIntegrity, before.remainingIntegrity)
        XCTAssertLessThan(
            try XCTUnwrap(after.automaticSecondsToBreak),
            try XCTUnwrap(before.automaticSecondsToBreak)
        )
    }
}
