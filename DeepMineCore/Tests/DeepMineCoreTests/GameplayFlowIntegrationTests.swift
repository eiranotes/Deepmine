import XCTest
@testable import DeepMineCore

final class GameplayFlowIntegrationTests: XCTestCase {
    func testMiningAdvisorPrioritizesFirstAutomationUnlock() {
        var player = PlayerState(
            resources: Resources(ore: 10_000),
            equipment: EquipmentLevels(drill: 4, cart: 1, lamp: 3),
            mineFace: MineFaceState(segmentIndex: 40)
        )
        XCTAssertFalse(MiningLoop.power(for: player).isAutomated)
        let recommendation = UpgradeAdvisor.recommendForMining(for: player)
        XCTAssertEqual(recommendation?.equipment, .cart)
        player.equipment.cart = 2
        XCTAssertTrue(MiningLoop.power(for: player).isAutomated)
    }

    func testBulkPurchaseStopsAtRememberedLevel() {
        var player = PlayerState(
            resources: Resources(ore: 1_000_000),
            equipment: EquipmentLevels(drill: 1, cart: 1, lamp: 1),
            rememberedEquipment: EquipmentLevels(drill: 4, cart: 3, lamp: 2),
            mineFace: MineFaceState(segmentIndex: 100)
        )
        let result = EquipmentEngine.purchaseBulk(
            BulkUpgradePurchaseCommand(
                id: UUID(),
                equipment: .drill,
                stopAtRememberedLevel: true
            ),
            in: &player
        )
        guard case let .purchased(_, level, count, _) = result else {
            return XCTFail("expected remembered rebuild")
        }
        XCTAssertEqual(level, 4)
        XCTAssertEqual(count, 3)
    }

    func testMiningDayDoesNotIncrementSessionCount() throws {
        let zone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var player = PlayerState()

        _ = try MiningStreak.record(
            at: date,
            in: &player,
            calendar: calendar,
            timeZone: zone,
            incrementSessionCount: false
        )
        XCTAssertEqual(player.streakDays, 1)
        XCTAssertEqual(player.dailyRecords.count, 1)
        XCTAssertEqual(player.dailyRecords[0].sessionCount, 0)

        _ = try MiningStreak.record(
            at: date,
            in: &player,
            calendar: calendar,
            timeZone: zone
        )
        XCTAssertEqual(player.dailyRecords[0].sessionCount, 1)
    }

    func testCrystalsPurchaseAndSelectLockedTheme() {
        var player = PlayerState(resources: Resources(crystals: 6))
        let result = WorldProgression.purchaseTheme(
            ThemePurchaseCommand(id: UUID(), theme: .ruins),
            in: &player
        )
        XCTAssertEqual(result, .purchased(theme: .ruins, cost: 6))
        XCTAssertEqual(player.resources.crystals, 0)
        XCTAssertTrue(player.unlockedThemes.contains(.ruins))
        XCTAssertEqual(player.selectedTheme, .ruins)
    }

    func testLampRefinementCriticalMultiplierSurvivesDoubleRange() {
        let power = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 1, cart: 1, lamp: 100_000),
            permanent: PermanentUpgradeLevels(),
            refinement: RefinementTiers(lamp: 10_000)
        )
        XCTAssertGreaterThan(power.criticalDamageMultiplier.exponent, 308)
        XCTAssertFalse(power.criticalDamageMultiplier.isZero)
    }

    func testEquipmentAndRefinementCostsRemainComparablePastDoubleRange() {
        let equipment = EquipmentEngine.upgradeCostBig(
            for: .drill,
            currentLevel: 10_000
        )
        let refinement = RefinementEngine.oreCostBig(for: .drill, tier: 1_000)
        XCTAssertNotNil(equipment)
        XCTAssertGreaterThan(equipment?.exponent ?? 0, 308)
        XCTAssertGreaterThan(refinement.exponent, 308)
    }
}
