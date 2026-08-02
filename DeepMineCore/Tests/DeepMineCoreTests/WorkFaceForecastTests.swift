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
        XCTAssertNil(forecast.automaticOrePerSecond)
        XCTAssertNil(forecast.automaticLayersPerSecond)
        XCTAssertFalse(forecast.isAutomated)
        XCTAssertNotNil(forecast.tapsToBreak)
    }

    func testAutomaticEtaAppearsWithTheFirstCartUpgrade() throws {
        let forecast = MiningLoop.forecast(for: player(cart: 2))
        let seconds = try XCTUnwrap(forecast.automaticSecondsToBreak)
        XCTAssertGreaterThan(seconds, 0)
        XCTAssertTrue(seconds.isFinite)
        XCTAssertGreaterThan(try XCTUnwrap(forecast.automaticOrePerSecond), .zero)
        XCTAssertGreaterThan(try XCTUnwrap(forecast.automaticLayersPerSecond), .zero)
        XCTAssertTrue(forecast.isAutomated)
    }

    func testCurrentProductionRatesUseTheWholeLayerEconomy() throws {
        let state = player(cart: 2)
        let forecast = MiningLoop.forecast(for: state)
        let power = MiningLoop.power(for: state)
        let layers = try XCTUnwrap(forecast.automaticLayersPerSecond)
        let ore = try XCTUnwrap(forecast.automaticOrePerSecond)

        XCTAssertEqual(layers, power.damagePerSecond / state.mineFace.segment.maximumIntegrity)
        XCTAssertEqual(ore, forecast.expectedOre * layers)
    }

    /// Late-game rates may be smaller and larger than `Double` at the same time: layer
    /// speed underflows while ore output overflows. Both still have to remain visible data.
    func testProductionRatesStayBigNumberNativeAtExtremeDepth() throws {
        var state = player(cart: 2)
        state.mineFace = MineFaceState(segmentIndex: 100_000)
        let forecast = MiningLoop.forecast(for: state)

        let layers = try XCTUnwrap(forecast.automaticLayersPerSecond)
        let ore = try XCTUnwrap(forecast.automaticOrePerSecond)
        XCTAssertFalse(layers.isZero)
        XCTAssertFalse(ore.isZero)
        XCTAssertEqual(layers.doubleValue, 0)
        XCTAssertEqual(ore.doubleValue, .greatestFiniteMagnitude)
        XCTAssertNil(forecast.automaticSecondsToBreak)
        XCTAssertTrue(forecast.isAutomated)
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

    func testTapCountRejectsTheRoundedIntMaximumBoundary() {
        var state = player()
        let tapDamage = MiningLoop.power(for: state).tapDamage
        state.mineFace = MineFaceState(
            remainingIntegrity: tapDamage * BigNumber(Double(Int.max))
        )

        XCTAssertNil(MiningLoop.forecast(for: state).tapsToBreak)
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

    func testDrillPurchaseImpactShowsExpectedTapOutputAndGain() throws {
        let before = player(drill: 1)
        var after = before
        after.equipment.drill = 2
        let impact = try XCTUnwrap(PurchaseImpact(
            before: before,
            after: after,
            equipment: .drill
        ))

        guard case let .tapOutput(old, new) = impact.metric else {
            return XCTFail("Expected tap output")
        }
        XCTAssertGreaterThan(new, old)
        XCTAssertEqual(
            try XCTUnwrap(impact.relativeIncrease).doubleValue,
            Balance.drillRewardGrowthRate - 1,
            accuracy: 0.000_001
        )
    }

    func testFirstCartImpactStartsAutomationWithoutFakePercentage() throws {
        let before = player(cart: 1)
        var after = before
        after.equipment.cart = 2
        let impact = try XCTUnwrap(PurchaseImpact(
            before: before,
            after: after,
            equipment: .cart
        ))

        guard case let .automaticOutput(old, new) = impact.metric else {
            return XCTFail("Expected automatic output")
        }
        XCTAssertNil(old)
        XCTAssertGreaterThan(new, .zero)
        XCTAssertNil(impact.relativeIncrease)
    }

    func testLaterCartImpactUsesEtaAndReportsTheOutputGain() throws {
        let before = player(cart: 2)
        var after = before
        after.equipment.cart = 3
        let impact = try XCTUnwrap(PurchaseImpact(
            before: before,
            after: after,
            equipment: .cart
        ))

        guard case let .automaticETA(old, new) = impact.metric else {
            return XCTFail("Expected automatic ETA")
        }
        XCTAssertLessThan(new, old)
        XCTAssertGreaterThan(try XCTUnwrap(impact.relativeIncrease), .zero)
    }

    func testLampImpactUsesExpectedCriticalOutput() throws {
        let before = player(lamp: 1)
        var after = before
        after.equipment.lamp = 2
        let impact = try XCTUnwrap(PurchaseImpact(
            before: before,
            after: after,
            equipment: .lamp
        ))

        guard case let .tapOutput(old, new) = impact.metric else {
            return XCTFail("Expected expected-tap output")
        }
        XCTAssertGreaterThan(new, old)
        XCTAssertGreaterThan(try XCTUnwrap(impact.relativeIncrease), .zero)
    }

    func testRefinementUsesTheSameImpactPath() throws {
        var drillBefore = player(drill: 7)
        var drillAfter = drillBefore
        drillAfter.refinementTiers.drill = 1
        let drill = try XCTUnwrap(PurchaseImpact(
            before: drillBefore,
            after: drillAfter,
            equipment: .drill
        ))
        XCTAssertEqual(
            try XCTUnwrap(drill.relativeIncrease).doubleValue,
            Balance.refinementDamageMultiplier - 1,
            accuracy: 0.000_001
        )

        drillBefore.equipment.lamp = 7
        var lampAfter = drillBefore
        lampAfter.refinementTiers.lamp = 1
        let lamp = try XCTUnwrap(PurchaseImpact(
            before: drillBefore,
            after: lampAfter,
            equipment: .lamp
        ))
        XCTAssertGreaterThan(try XCTUnwrap(lamp.relativeIncrease), .zero)
        XCTAssertLessThan(
            try XCTUnwrap(lamp.relativeIncrease).doubleValue,
            Balance.refinementDamageMultiplier - 1
        )
    }

    func testRefinementImpactUsesExactPerEquipmentCoreMultiplier() throws {
        XCTAssertEqual(
            RefinementImpact.coreMultiplier(for: .cart, in: player(cart: 1)),
            BigNumber(Balance.refinementDamageMultiplier)
        )
        var drillBefore = player(drill: 7)
        var drillAfter = drillBefore
        drillAfter.refinementTiers.drill = 1
        let drill = try XCTUnwrap(RefinementImpact(
            before: drillBefore,
            after: drillAfter,
            equipment: .drill
        ))
        XCTAssertEqual(drill.beforeTier, 0)
        XCTAssertEqual(drill.afterTier, 1)
        XCTAssertEqual(
            drill.coreMultiplier.doubleValue,
            Balance.refinementDamageMultiplier,
            accuracy: 0.000_001
        )

        drillBefore.equipment.lamp = 7
        var lampAfter = drillBefore
        lampAfter.refinementTiers.lamp = 1
        let lamp = try XCTUnwrap(RefinementImpact(
            before: drillBefore,
            after: lampAfter,
            equipment: .lamp
        ))
        let beforeCritical = MiningLoop.power(for: drillBefore).criticalDamageMultiplier
        let afterCritical = MiningLoop.power(for: lampAfter).criticalDamageMultiplier
        XCTAssertEqual(
            lamp.coreMultiplier.doubleValue,
            (afterCritical / beforeCritical).doubleValue,
            accuracy: 0.000_001
        )
        XCTAssertLessThan(
            lamp.coreMultiplier.doubleValue,
            sqrt(Balance.refinementDamageMultiplier)
        )
        XCTAssertEqual(
            RefinementImpact.coreMultiplier(for: .lamp, in: drillBefore),
            lamp.coreMultiplier
        )
        XCTAssertEqual(
            RefinementImpact.coreMultiplier(for: .lamp, in: player(lamp: 1)),
            lamp.coreMultiplier
        )
    }

    func testImpactDoesNotInventAChangeForIdenticalSnapshots() {
        let state = player()
        XCTAssertNil(PurchaseImpact(before: state, after: state, equipment: .drill))
        XCTAssertNil(PurchaseImpact(before: state, after: state, equipment: .cart))
        XCTAssertNil(PurchaseImpact(before: state, after: state, equipment: .lamp))
    }
}
