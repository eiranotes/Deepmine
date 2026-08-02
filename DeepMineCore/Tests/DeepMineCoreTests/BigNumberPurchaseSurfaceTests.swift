import Foundation
import XCTest
@testable import DeepMineCore

/// Purchase APIs are player-facing economy boundaries. Values beyond `Double` must not
/// collapse to the same maximum sentinel before UI and telemetry receive them.
final class BigNumberPurchaseSurfaceTests: XCTestCase {
    private let lateGameLevel = 3_000

    func testSinglePurchaseReturnsExactCostPastDoubleRange() throws {
        let cost = try XCTUnwrap(
            EquipmentEngine.upgradeCostBig(for: .drill, currentLevel: lateGameLevel)
        )
        XCTAssertGreaterThan(cost.exponent, 308)
        var player = lateGamePlayer(ore: cost * 2)

        let result = EquipmentEngine.purchase(
            UpgradePurchaseCommand(id: UUID(), equipment: .drill),
            in: &player
        )

        guard case let .purchased(equipment, newLevel, reportedCost) = result else {
            return XCTFail("expected purchase, got \(result)")
        }
        XCTAssertEqual(equipment, .drill)
        XCTAssertEqual(newLevel, lateGameLevel + 1)
        XCTAssertEqual(reportedCost, cost)
        XCTAssertEqual(player.resources.ore, cost)
    }

    func testShortfallReturnsExactRequiredAndAvailablePastDoubleRange() throws {
        let required = try XCTUnwrap(
            EquipmentEngine.upgradeCostBig(for: .drill, currentLevel: lateGameLevel)
        )
        let available = required / 2
        var player = lateGamePlayer(ore: available)

        let result = EquipmentEngine.purchase(
            UpgradePurchaseCommand(id: UUID(), equipment: .drill),
            in: &player
        )

        XCTAssertEqual(result, .insufficientOre(required: required, available: available))
        XCTAssertEqual(player.resources.ore, available)
    }

    func testBulkPurchaseReturnsExactTotalPastDoubleRange() throws {
        let first = try XCTUnwrap(
            EquipmentEngine.upgradeCostBig(for: .cart, currentLevel: lateGameLevel)
        )
        let second = try XCTUnwrap(
            EquipmentEngine.upgradeCostBig(for: .cart, currentLevel: lateGameLevel + 1)
        )
        let total = first + second
        // Leave headroom: subtracting two similarly-sized normalized mantissas can lose
        // the final ulp, which must not turn this contract test into a precision test.
        var player = lateGamePlayer(ore: total * 2)

        let result = EquipmentEngine.purchaseBulk(
            BulkUpgradePurchaseCommand(
                id: UUID(),
                equipment: .cart,
                maximumPurchases: 2
            ),
            in: &player
        )

        XCTAssertEqual(
            result,
            .purchased(
                equipment: .cart,
                newLevel: lateGameLevel + 2,
                levelsBought: 2,
                totalCost: total
            )
        )
        XCTAssertGreaterThan(player.resources.ore, .zero)
    }

    func testRefinementReturnsExactCostPastDoubleRange() {
        let unlocked = RefinementEngine.unlockedTiers(forLevel: lateGameLevel)
        let currentTier = unlocked - 1
        let nextTier = currentTier + 1
        let cost = RefinementEngine.oreCostBig(for: .lamp, tier: nextTier)
        XCTAssertGreaterThan(cost.exponent, 308)
        var player = lateGamePlayer(
            ore: cost * 2,
            refinement: RefinementTiers(lamp: currentTier)
        )

        let result = RefinementEngine.purchase(.lamp, in: &player)

        XCTAssertEqual(
            result,
            .refined(equipment: .lamp, newTier: nextTier, cost: cost)
        )
        XCTAssertEqual(player.resources.ore, cost)
    }

    func testRecommendationCarriesExactCostPastDoubleRange() throws {
        let drillCost = try XCTUnwrap(
            EquipmentEngine.upgradeCostBig(for: .drill, currentLevel: lateGameLevel)
        )
        let player = lateGamePlayer(ore: drillCost * 100)
        let recommendation = try XCTUnwrap(UpgradeAdvisor.recommend(
            for: player,
            marginalExpectedOre: [.drill: 10, .cart: 1, .lamp: 1]
        ))

        XCTAssertEqual(recommendation.equipment, .drill)
        XCTAssertEqual(recommendation.bigCost, drillCost)
        XCTAssertGreaterThan(recommendation.bigCost.exponent, 308)
        XCTAssertEqual(recommendation.cost, .greatestFiniteMagnitude)
        XCTAssertNotEqual(BigNumber(recommendation.cost), recommendation.bigCost)
    }

    func testLegacyRecommendationPayloadRecoversBigCost() throws {
        let legacy = Data("""
            {
              "equipment": "drill",
              "currentLevel": 1,
              "nextLevel": 2,
              "cost": 100,
              "marginalExpectedOre": 12,
              "efficiency": 0.12,
              "isRemembered": false
            }
            """.utf8)

        let recommendation = try JSONDecoder().decode(
            UpgradeRecommendation.self,
            from: legacy
        )

        XCTAssertEqual(recommendation.bigCost, 100)
        XCTAssertEqual(
            try JSONDecoder().decode(
                UpgradeRecommendation.self,
                from: JSONEncoder().encode(recommendation)
            ),
            recommendation
        )
    }

    private func lateGamePlayer(
        ore: BigNumber,
        refinement: RefinementTiers = .none
        ) -> PlayerState {
        let requiredDepth = EquipmentEngine.requiredDepth(forLevel: lateGameLevel + 2)
        let requiredSegment = (
            requiredDepth + Balance.metersPerSegment - 1
        ) / Balance.metersPerSegment
        return PlayerState(
            resources: Resources(ore: ore),
            equipment: EquipmentLevels(
                drill: lateGameLevel,
                cart: lateGameLevel,
                lamp: lateGameLevel
            ),
            refinementTiers: refinement,
            mineFace: MineFaceState(
                segmentIndex: requiredSegment
            )
        )
    }
}
