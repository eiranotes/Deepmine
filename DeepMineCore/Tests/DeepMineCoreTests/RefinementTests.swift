import XCTest
@testable import DeepMineCore

/// The second multiplicative axis. Its whole purpose is to clear a deficit the level
/// ladder cannot: ore buys 0.2312 levels per segment, those buy 1.0265 damage, and
/// integrity compounds at 1.058. Refinement has to make up the difference and no more.
final class RefinementTests: XCTestCase {
    private func state(
        drill: Int = 1,
        cart: Int = 1,
        lamp: Int = 1,
        ore: BigNumber = .zero
    ) -> PlayerState {
        var state = PlayerState()
        state.equipment = EquipmentLevels(drill: drill, cart: cart, lamp: lamp)
        state.resources.ore = ore
        return state
    }

    /// The number the whole design turns on. If this fails, growth stalls again.
    func testRefinementClearsTheIntegrityDeficitWithHeadroom() {
        let levelsPerSegment = log(Balance.segmentOreGrowthRate)
            / log(Balance.equipmentPriceGrowthRate)
        let damagePerSegment = pow(Balance.drillRewardGrowthRate, levelsPerSegment)
        let refinementPerSegment = pow(
            Balance.refinementDamageMultiplier,
            levelsPerSegment / Double(Balance.refinementLevelInterval)
        )
        let combined = damagePerSegment * refinementPerSegment

        XCTAssertGreaterThan(combined, Balance.segmentIntegrityGrowthRate)
        // Headroom, not a runaway: a descent that gently accelerates rather than one that
        // trivialises itself. x3.0 would land near +1.4%.
        // Five levels per tier would overshoot to +1.23%; seven is the exact balance point.
        let headroom = combined / Balance.segmentIntegrityGrowthRate - 1
        XCTAssertLessThan(headroom, 0.01, "headroom \(headroom)")
        XCTAssertGreaterThan(headroom, 0.002, "headroom \(headroom)")
    }

    func testTiersUnlockEveryIntervalAndNotBefore() {
        let step = Balance.refinementLevelInterval
        XCTAssertEqual(RefinementEngine.unlockedTiers(forLevel: 1), 0)
        XCTAssertEqual(RefinementEngine.unlockedTiers(forLevel: step), 0)
        XCTAssertEqual(RefinementEngine.unlockedTiers(forLevel: step + 1), 1)
        XCTAssertEqual(RefinementEngine.unlockedTiers(forLevel: step * 2 + 1), 2)
        XCTAssertEqual(RefinementEngine.requiredLevel(forTier: 1), step + 1)
        XCTAssertEqual(RefinementEngine.requiredLevel(forTier: 3), step * 3 + 1)
    }

    func testBuyingBeforeTheUnlockIsRefusedWithTheLevelItNeeds() {
        var player = state(drill: 3, ore: 1e12)
        guard case let .locked(required) = RefinementEngine.purchase(.drill, in: &player) else {
            return XCTFail("expected locked")
        }
        XCTAssertEqual(required, RefinementEngine.requiredLevel(forTier: 1))
        XCTAssertEqual(player.resources.ore.doubleValue, 1e12)
    }

    func testBuyingSpendsOreAndRaisesTheTier() {
        let cost = RefinementEngine.oreCostBig(for: .drill, tier: 1)
        var player = state(drill: 30, ore: cost + 500)
        XCTAssertEqual(
            RefinementEngine.purchase(.drill, in: &player),
            .refined(equipment: .drill, newTier: 1, cost: cost)
        )
        XCTAssertEqual(player.refinementTiers.drill, 1)
        XCTAssertEqual(player.resources.ore.doubleValue, 500, accuracy: 0.001)
    }

    func testCommandReplayDoesNotSpendOreOrRaiseTheTierTwice() {
        let cost = RefinementEngine.oreCostBig(for: .drill, tier: 1)
        let command = RefinementPurchaseCommand(id: UUID(), equipment: .drill)
        var player = state(drill: 30, ore: cost + 500)

        XCTAssertEqual(
            RefinementEngine.purchase(command, in: &player),
            .refined(equipment: .drill, newTier: 1, cost: cost)
        )
        XCTAssertEqual(RefinementEngine.purchase(command, in: &player), .duplicate)
        XCTAssertEqual(player.refinementTiers.drill, 1)
        XCTAssertEqual(player.resources.ore.doubleValue, 500, accuracy: 0.001)
        XCTAssertTrue(player.appliedPurchaseIDs.contains(command.id))
    }

    func testOreShortfallReportsBothSides() {
        var player = state(drill: 30, ore: 1)
        XCTAssertEqual(
            RefinementEngine.purchase(.drill, in: &player),
            .insufficientOre(
                required: RefinementEngine.oreCostBig(for: .drill, tier: 1),
                available: 1
            )
        )
        XCTAssertEqual(player.refinementTiers.drill, 0)
    }

    /// The axis must be reachable without focus. Ore comes out of rock; crystals come out
    /// of veins, which come out of sessions, and pricing refinement in them let focus own
    /// the economy (D-068).
    func testRefinementCostsOreRatherThanCrystals() {
        let cost = RefinementEngine.oreCostBig(for: .drill, tier: 1)
        var player = state(drill: 30, ore: cost)
        player.resources.crystals = 99
        _ = RefinementEngine.purchase(.drill, in: &player)
        XCTAssertEqual(player.resources.crystals, 99)
        XCTAssertEqual(player.resources.ore.doubleValue, 0, accuracy: 0.001)
    }

    /// A tier has to cost more than the levels it sits between, or climbing would never
    /// be worth it.
    func testATierCostsMoreThanTheLevelThatUnlocksIt() {
        let unlock = RefinementEngine.requiredLevel(forTier: 2)
        let levelCost = EquipmentEngine.upgradeCost(for: .drill, currentLevel: unlock) ?? 0
        XCTAssertGreaterThan(RefinementEngine.oreCost(for: .drill, tier: 2), levelCost * 10)
    }

    func testEachTierMultipliesDamage() {
        let plain = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 30, cart: 30, lamp: 1),
            permanent: PermanentUpgradeLevels()
        )
        let refined = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 30, cart: 30, lamp: 1),
            permanent: PermanentUpgradeLevels(),
            refinement: RefinementTiers(drill: 1, cart: 1)
        )

        XCTAssertEqual(
            refined.tapDamage.doubleValue / plain.tapDamage.doubleValue,
            Balance.refinementDamageMultiplier,
            accuracy: 0.001
        )
        XCTAssertEqual(
            refined.damagePerSecond.doubleValue / plain.damagePerSecond.doubleValue,
            Balance.refinementDamageMultiplier,
            accuracy: 0.001
        )
    }

    /// Lamp tiers must not be poured into a capped stat.
    func testLampRefinementRaisesTheCriticalMultiplierNotTheCappedChance() {
        let plain = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 1, cart: 1, lamp: 30),
            permanent: PermanentUpgradeLevels()
        )
        let refined = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 1, cart: 1, lamp: 30),
            permanent: PermanentUpgradeLevels(),
            refinement: RefinementTiers(lamp: 2)
        )
        XCTAssertEqual(refined.criticalChance, plain.criticalChance)
        XCTAssertGreaterThan(refined.criticalMultiplier, plain.criticalMultiplier)
    }

    /// A tool's tiers never touch another tool's output.
    func testTiersAreIndependentPerTool() {
        let drillOnly = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 30, cart: 30, lamp: 1),
            permanent: PermanentUpgradeLevels(),
            refinement: RefinementTiers(drill: 1)
        )
        let plain = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 30, cart: 30, lamp: 1),
            permanent: PermanentUpgradeLevels()
        )
        XCTAssertEqual(drillOnly.damagePerSecond, plain.damagePerSecond)
        XCTAssertGreaterThan(drillOnly.tapDamage, plain.tapDamage)
    }

    /// Prestige takes the tiers with the levels that unlocked them.
    func testPrestigeResetsRefinement() {
        var player = state(
            drill: 30,
            ore: RefinementEngine.oreCostBig(for: .drill, tier: 1)
        )
        _ = RefinementEngine.purchase(.drill, in: &player)
        XCTAssertEqual(player.refinementTiers.drill, 1)

        player.runSegmentsBroken = 100_000
        _ = PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &player)
        XCTAssertEqual(player.refinementTiers, .none)
    }

    /// Saves written before refinement existed must open unchanged.
    func testLegacySavesDecodeWithNoTiers() throws {
        var player = PlayerState()
        player.resources.ore = 42
        let data = try JSONEncoder().encode(player)
        var object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        object.removeValue(forKey: "refinementTiers")

        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(PlayerState.self, from: legacy)
        XCTAssertEqual(decoded.refinementTiers, .none)
        XCTAssertEqual(decoded.resources.ore, 42)
    }
}
