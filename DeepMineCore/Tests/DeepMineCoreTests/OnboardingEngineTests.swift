import XCTest
@testable import DeepMineCore

final class OnboardingEngineTests: XCTestCase {
    func testBreakingTheFirstRealRockAwardsExactlyOneDrillUpgrade() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let rewardID = UUID()
        let purchaseID = UUID()
        var state = PlayerState()
        var generator = SeededGenerator(seed: 42)

        let first = OnboardingEngine.strikeDemo(
            at: start,
            receiptID: rewardID,
            using: &generator,
            in: &state
        )
        guard case let .struck(firstUpdate) = first else {
            return XCTFail("The first tap should damage, not finish, the first rock")
        }
        XCTAssertGreaterThan(firstUpdate.damage, .zero)
        XCTAssertGreaterThan(state.mineFace.brokenFraction, 0)
        XCTAssertEqual(state.onboardingStage, .demo)

        var completion: DemoStrikeResult = first
        for _ in 0..<20 {
            completion = OnboardingEngine.strikeDemo(
                at: start,
                receiptID: rewardID,
                using: &generator,
                in: &state
            )
            if case .rewarded = completion { break }
        }
        guard case let .rewarded(update, ore, vein) = completion else {
            return XCTFail("The first rock did not break within the tutorial tap budget")
        }
        XCTAssertTrue(update.brokeSomething)
        XCTAssertEqual(ore, Balance.demoOreGrant)
        XCTAssertEqual(vein, Balance.demoGuaranteedVein)
        XCTAssertEqual(state.mineFace.segmentIndex, 1)
        XCTAssertEqual(state.depthMeters, Balance.metersPerSegment)
        XCTAssertEqual(state.resources.ore, Balance.drillBasePrice)
        XCTAssertEqual(state.resources.crystals, 1)
        XCTAssertEqual(state.completedSessionCount, 0)
        XCTAssertEqual(state.lifetimeFocusCredits, 0)
        XCTAssertFalse(state.isDeepMiningUnlocked)

        XCTAssertEqual(
            OnboardingEngine.purchaseRecommendedUpgrade(commandID: purchaseID, in: &state),
            .purchased(equipment: .drill, newLevel: 2, cost: Balance.drillBasePrice)
        )
        XCTAssertEqual(state.equipment.drill, 2)
        XCTAssertEqual(state.resources.ore, 0)
        XCTAssertEqual(state.onboardingStage, .complete)
        XCTAssertEqual(state.focusProtectionPermission, .notAsked)
        XCTAssertEqual(state.endAlertPermission, .notAsked)
        XCTAssertEqual(state.returnReminderPermission, .notAsked)
    }

    func testDemoAndUpgradeAreIdempotent() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let rewardID = UUID()
        let purchaseID = UUID()
        var state = PlayerState()
        var generator = SeededGenerator(seed: 7)
        for _ in 0..<20 {
            let result = OnboardingEngine.strikeDemo(
                at: start,
                receiptID: rewardID,
                using: &generator,
                in: &state
            )
            if case .rewarded = result { break }
        }
        _ = OnboardingEngine.purchaseRecommendedUpgrade(commandID: purchaseID, in: &state)

        XCTAssertEqual(
            OnboardingEngine.strikeDemo(
                at: start.addingTimeInterval(180),
                receiptID: UUID(),
                using: &generator,
                in: &state
            ),
            .alreadyRewarded
        )
        XCTAssertEqual(
            OnboardingEngine.purchaseRecommendedUpgrade(commandID: purchaseID, in: &state),
            .duplicate
        )
        XCTAssertEqual(state.equipment.drill, 2)
    }

    func testLegacyPremiseStageCanEnterTheInteractiveRock() {
        var state = PlayerState(onboardingStage: .premiseSessions)
        var generator = SeededGenerator(seed: 3)

        _ = OnboardingEngine.strikeDemo(
            at: Date(timeIntervalSince1970: 1_800_000_000),
            receiptID: UUID(),
            using: &generator,
            in: &state
        )

        XCTAssertEqual(state.onboardingStage, .demo)
        XCTAssertNotNil(state.demoStartedAt)
        XCTAssertGreaterThan(state.mineFace.brokenFraction, 0)
    }

    func testSelectionsPersistOnlyUnlockedPlan() {
        var state = PlayerState()
        OnboardingEngine.select(plan: .deep, in: &state)
        OnboardingEngine.select(duration: .minutes50, in: &state)
        XCTAssertEqual(state.lastSelectedPlan, .safe)
        XCTAssertEqual(state.lastSelectedDuration, .minutes50)

        state = PlayerState(completedSessionCount: 3)
        OnboardingEngine.select(plan: .deep, in: &state)
        XCTAssertEqual(state.lastSelectedPlan, .deep)
    }
}
