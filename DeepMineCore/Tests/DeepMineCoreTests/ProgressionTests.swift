import Foundation
import XCTest
@testable import DeepMineCore

final class ProgressionTests: XCTestCase {
    func testSessionLengthsAdvanceExactFocusCredits() throws {
        let examples: [(SessionLength, Double)] = [
            (.minutes15, 0.6), (.minutes25, 1), (.minutes50, 2)
        ]
        for (length, expectedCredits) in examples {
            var state = PlayerState()
            let input = rewardInput(length: length)
            let reward = try RewardCalculator.calculate(input)

            XCTAssertEqual(
                try ProgressionEngine.apply(
                    reward: reward, input: input,
                    completedAt: Date(timeIntervalSince1970: 100), to: &state
                ),
                .applied
            )
            XCTAssertEqual(state.runFocusCredits, expectedCredits, accuracy: 1e-12)
            XCTAssertEqual(state.lifetimeFocusCredits, expectedCredits, accuracy: 1e-12)
            XCTAssertEqual(state.completedSessionCount, 1)
            XCTAssertEqual(state.resources.ore, reward.ore, accuracy: 1e-12)
        }
    }

    func testDeepUnlocksOnThirdCompletedSession() throws {
        var state = PlayerState()
        for count in 1...3 {
            let input = rewardInput()
            let reward = try RewardCalculator.calculate(input)
            try ProgressionEngine.apply(
                reward: reward, input: input,
                completedAt: Date(timeIntervalSince1970: Double(count)), to: &state
            )
            XCTAssertEqual(state.isDeepMiningUnlocked, count >= 3)
        }
    }

    func testAbandonmentAddsFocusButNotACompletion() throws {
        var state = PlayerState()
        let input = rewardInput(outcome: .abandoned(elapsedMinutes: 10))
        let reward = try RewardCalculator.calculate(input)
        try ProgressionEngine.apply(reward: reward, input: input, completedAt: Date(), to: &state)

        XCTAssertEqual(state.runFocusCredits, 0.4, accuracy: 1e-12)
        XCTAssertEqual(state.completedSessionCount, 0)
        XCTAssertFalse(state.isDeepMiningUnlocked)
    }

    func testDepthUsesLifetimeCreditsFloorAndBonus() {
        XCTAssertEqual(ProgressionEngine.depth(lifetimeFocusCredits: 0), 0)
        XCTAssertEqual(ProgressionEngine.depth(lifetimeFocusCredits: 1), 12)
        XCTAssertEqual(ProgressionEngine.depth(lifetimeFocusCredits: 2), 26)
        XCTAssertEqual(ProgressionEngine.depth(lifetimeFocusCredits: 10), 169)
        XCTAssertEqual(ProgressionEngine.depth(lifetimeFocusCredits: 2, bonusDepthMeters: 60), 86)
    }

    func testLevelTwoPricesAndEffectsAreExact() {
        XCTAssertEqual(EquipmentEngine.upgradeCost(for: .drill, currentLevel: 1), 100)
        XCTAssertEqual(EquipmentEngine.upgradeCost(for: .cart, currentLevel: 1), 180)
        XCTAssertEqual(EquipmentEngine.upgradeCost(for: .lamp, currentLevel: 1), 200)
        XCTAssertEqual(EquipmentEngine.drillRewardMultiplier(level: 2), 1.12, accuracy: 1e-12)
        XCTAssertEqual(EquipmentEngine.cartLengthMultiplier(length: .minutes15, level: 2), 1)
        XCTAssertEqual(
            EquipmentEngine.cartLengthMultiplier(length: .minutes25, level: 2),
            1.10 * 1.05,
            accuracy: 1e-12
        )
        XCTAssertEqual(
            EquipmentEngine.cartLengthMultiplier(length: .minutes50, level: 2),
            1.30 * 1.07,
            accuracy: 1e-12
        )
        XCTAssertEqual(EquipmentEngine.lampChanceBonus(level: 2), 0.012, accuracy: 1e-12)
    }

    func testCompoundingKeepsEveryLevelWorthTheSameRelativeGain() {
        for level in [1, 10, 25, 59] {
            let ratio = EquipmentEngine.drillRewardMultiplier(level: level + 1)
                / EquipmentEngine.drillRewardMultiplier(level: level)
            XCTAssertEqual(ratio, Balance.drillRewardGrowthRate, accuracy: 1e-12)
        }
    }

    func testUpgradePricesUseCeilingAndStopAtMaximumLevel() {
        XCTAssertEqual(EquipmentEngine.upgradeCost(for: .drill, currentLevel: 2), 134)
        XCTAssertEqual(EquipmentEngine.upgradeCost(for: .drill, currentLevel: 3), 180)
        XCTAssertNil(
            EquipmentEngine.upgradeCost(for: .drill, currentLevel: Balance.maximumEquipmentLevel)
        )
    }

    func testRememberedLevelsCostHalfSoPrestigeRebuildsFast() {
        let full = try? XCTUnwrap(EquipmentEngine.upgradeCost(for: .drill, currentLevel: 8))
        let discounted = EquipmentEngine.upgradeCost(
            for: .drill,
            currentLevel: 8,
            rememberedLevel: 14
        )
        XCTAssertEqual(discounted, (full.flatMap { $0 }).map { ceil($0 * 0.5) })
        // Beyond the remembered peak the discount stops.
        XCTAssertEqual(
            EquipmentEngine.upgradeCost(for: .drill, currentLevel: 14, rememberedLevel: 14),
            EquipmentEngine.upgradeCost(for: .drill, currentLevel: 14)
        )
    }

    func testDepthUnlocksTheEquipmentCeiling() {
        XCTAssertEqual(Balance.maximumEquipmentLevel(forDepth: 0), Balance.equipmentLevelUnlockBase)
        XCTAssertEqual(Balance.maximumEquipmentLevel(forDepth: 600), 45)
        XCTAssertEqual(
            Balance.maximumEquipmentLevel(forDepth: 1_000_000),
            Balance.maximumEquipmentLevel
        )
        XCTAssertEqual(EquipmentEngine.requiredDepth(forLevel: 6), 15)
        XCTAssertEqual(EquipmentEngine.requiredDepth(forLevel: 45), 600)
        // The rail must not bind on ore the player dug out of the rock itself: a segment
        // pays for more ceiling than it consumes.
        let levelsPerSegment = Double(Balance.metersPerSegment) / Double(Balance.equipmentLevelUnlockDepthStep)
        let levelsOreBuysPerSegment = log(Balance.segmentOreGrowthRate) / log(Balance.equipmentPriceGrowthRate)
        XCTAssertGreaterThan(levelsPerSegment, levelsOreBuysPerSegment)
    }

    func testPurchaseChecksAffordabilityMaximumAndReplay() {
        let command = UpgradePurchaseCommand(id: UUID(), equipment: .drill)
        var state = PlayerState(resources: Resources(ore: 99))
        XCTAssertEqual(
            EquipmentEngine.purchase(command, in: &state),
            .insufficientOre(required: 100, available: 99)
        )
        XCTAssertEqual(state.equipment.drill, 1)

        state.resources.ore = 100
        XCTAssertEqual(
            EquipmentEngine.purchase(command, in: &state),
            .purchased(equipment: .drill, newLevel: 2, cost: 100)
        )
        XCTAssertEqual(state.resources.ore, 0)
        XCTAssertEqual(state.equipment.drill, 2)

        state.resources.ore = 1_000
        XCTAssertEqual(EquipmentEngine.purchase(command, in: &state), .duplicate)
        XCTAssertEqual(state.resources.ore, 1_000)
        XCTAssertEqual(state.equipment.drill, 2)

        for equipment in EquipmentKind.allCases {
            let ceiling = Balance.maximumEquipmentLevel
            var capped = PlayerState(
                resources: Resources(ore: .greatestFiniteMagnitude),
                equipment: EquipmentLevels(drill: ceiling, cart: ceiling, lamp: ceiling),
                lifetimeFocusCredits: 200,
                // Deep enough that the depth rail is not what stops the purchase.
                mineFace: MineFaceState(
                    segmentIndex: EquipmentEngine.requiredDepth(forLevel: ceiling)
                        / Balance.metersPerSegment
                )
            )
            XCTAssertEqual(
                EquipmentEngine.purchase(
                    UpgradePurchaseCommand(id: UUID(), equipment: equipment), in: &capped
                ),
                .maximumLevel
            )
        }
    }

    func testPurchaseIsBlockedByDepthBeforeOre() {
        var shallow = PlayerState(
            resources: Resources(ore: 1_000_000),
            equipment: EquipmentLevels(drill: 5, cart: 1, lamp: 1)
        )
        XCTAssertEqual(
            EquipmentEngine.purchase(
                UpgradePurchaseCommand(id: UUID(), equipment: .drill), in: &shallow
            ),
            .depthLocked(
                unlockedLevel: Balance.equipmentLevelUnlockBase,
                requiredDepthMeters: Balance.equipmentLevelUnlockDepthStep
            )
        )
        XCTAssertEqual(shallow.resources.ore, 1_000_000)
        XCTAssertEqual(shallow.equipment.drill, 5)
    }

    func testPurchaseRecordsTheRememberedPeak() {
        var state = PlayerState(resources: Resources(ore: 1_000), lifetimeFocusCredits: 200)
        XCTAssertEqual(state.rememberedEquipment.drill, 1)
        _ = EquipmentEngine.purchase(
            UpgradePurchaseCommand(id: UUID(), equipment: .drill), in: &state
        )
        XCTAssertEqual(state.equipment.drill, 2)
        XCTAssertEqual(state.rememberedEquipment.drill, 2)
    }

    func testAdvisorUsesEfficiencyAndDrillTieBreak() {
        let state = PlayerState(resources: Resources(ore: 1_000))
        let recommendation = UpgradeAdvisor.recommend(
            for: state,
            marginalExpectedOre: [.drill: 100, .cart: 180, .lamp: 1]
        )
        XCTAssertEqual(recommendation?.equipment, .drill)
        XCTAssertEqual(recommendation?.efficiency, 1)

        let cartBest = UpgradeAdvisor.recommend(
            for: state,
            marginalExpectedOre: [.drill: 1, .cart: 36, .lamp: 1]
        )
        XCTAssertEqual(cartBest?.equipment, .cart)
        XCTAssertNil(UpgradeAdvisor.recommend(
            for: PlayerState(resources: Resources(ore: 99)),
            marginalExpectedOre: [.drill: 100, .cart: 180, .lamp: 260]
        ))
    }

    func testAdvisorProjectsExactNextSessionMarginalOre() throws {
        let state = PlayerState(resources: Resources(ore: 1_000))
        let marginal = try UpgradeAdvisor.marginalExpectedOre(
            for: state, nextSession: rewardInput(length: .minutes50)
        )
        XCTAssertEqual(marginal[.drill] ?? 0, 33.3528, accuracy: 1e-9)
        XCTAssertEqual(marginal[.cart] ?? 0, 19.4558, accuracy: 1e-9)
        // The lamp is no longer valued at blue veins alone.
        XCTAssertEqual(marginal[.lamp] ?? 0, 1.794, accuracy: 1e-9)
        let recommendation = try UpgradeAdvisor.recommend(
            for: state,
            nextSession: rewardInput(length: .minutes50)
        )
        XCTAssertNotNil(recommendation)
        XCTAssertGreaterThan(recommendation?.marginalExpectedOre ?? 0, 0)
        XCTAssertEqual(
            recommendation,
            UpgradeAdvisor.recommend(
                for: state,
                marginalExpectedOre: marginal
            )
        )
    }

    func testProgressionAndPurchaseIDsAreIdempotent() throws {
        var state = PlayerState(resources: Resources(ore: 1_000))
        let input = rewardInput()
        let reward = try RewardCalculator.calculate(input)
        XCTAssertEqual(
            try ProgressionEngine.apply(reward: reward, input: input, completedAt: Date(), to: &state),
            .applied
        )
        let snapshot = state
        XCTAssertEqual(
            try ProgressionEngine.apply(reward: reward, input: input, completedAt: Date(), to: &state),
            .duplicate
        )
        XCTAssertEqual(state, snapshot)
    }

    func testHistoryIsBoundedAndCodableRoundTrips() throws {
        let entries = (0...Balance.sessionHistoryLimit).map { index in
            SessionHistoryEntry(
                completionID: UUID(), endedAt: Date(timeIntervalSince1970: Double(index)),
                focusedMinutes: 25, focusCredits: 1, plan: .safe,
                verificationGrade: .sealed, oreEarned: 100,
                vein: nil, depthAfter: index, completed: true
            )
        }
        let state = PlayerState(
            resources: Resources(ore: 10, crystals: 2, coreShards: 1),
            runFocusCredits: 10, lifetimeFocusCredits: 20,
            completedSessionCount: 10, bonusDepthMeters: 60, history: entries
        )
        XCTAssertEqual(state.history.count, Balance.sessionHistoryLimit)
        XCTAssertEqual(state.history.first?.depthAfter, 1)
        var unbounded = state
        unbounded.history = entries
        let data = try JSONEncoder().encode(unbounded)
        let decoded = try JSONDecoder().decode(PlayerState.self, from: data)
        XCTAssertEqual(decoded.history.count, Balance.sessionHistoryLimit)
        XCTAssertEqual(decoded.history.first?.depthAfter, 1)
        let boundedData = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(PlayerState.self, from: boundedData), state)
    }

    private func rewardInput(
        length: SessionLength = .minutes25,
        outcome: SessionOutcome = .completed
    ) -> RewardInput {
        RewardInput(
            completionID: UUID(), outcome: outcome, sessionLength: length,
            plan: .safe, verificationGrade: .sealed, growthFocusCredits: 0,
            streakDays: 1, dailySessionNumber: 1, equipment: EquipmentLevels(),
            vein: nil, resonanceBoostActive: false
        )
    }
}
