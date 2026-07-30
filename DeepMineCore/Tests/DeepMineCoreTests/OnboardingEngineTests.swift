import XCTest
@testable import DeepMineCore

final class OnboardingEngineTests: XCTestCase {
    func testDemoAwardsExactlyOneDrillUpgradeWithoutNormalProgress() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let rewardID = UUID()
        let purchaseID = UUID()
        var state = PlayerState()

        XCTAssertEqual(
            OnboardingEngine.beginDemo(at: start, in: &state),
            .started(endsAt: start.addingTimeInterval(90))
        )
        XCTAssertEqual(
            OnboardingEngine.completeDemo(at: start.addingTimeInterval(89), receiptID: rewardID, in: &state),
            .tooEarly(remainingSeconds: 1)
        )
        XCTAssertEqual(
            OnboardingEngine.completeDemo(at: start.addingTimeInterval(90), receiptID: rewardID, in: &state),
            .rewarded(ore: Balance.demoOreGrant)
        )
        XCTAssertEqual(state.resources.ore, Balance.drillBasePrice)
        XCTAssertEqual(state.completedSessionCount, 0)
        XCTAssertEqual(state.lifetimeFocusCredits, 0)
        XCTAssertFalse(state.isDeepMiningUnlocked)

        XCTAssertEqual(
            OnboardingEngine.purchaseRecommendedUpgrade(commandID: purchaseID, in: &state),
            .purchased(equipment: .drill, newLevel: 2, cost: Balance.drillBasePrice)
        )
        XCTAssertEqual(state.equipment.drill, 2)
        XCTAssertEqual(state.resources.ore, 0)
        XCTAssertEqual(state.onboardingStage, .permissions)
    }

    func testDemoAndUpgradeAreIdempotent() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let rewardID = UUID()
        let purchaseID = UUID()
        var state = PlayerState()
        _ = OnboardingEngine.beginDemo(at: start, in: &state)
        _ = OnboardingEngine.completeDemo(
            at: start.addingTimeInterval(Balance.demoDurationSeconds),
            receiptID: rewardID,
            in: &state
        )
        _ = OnboardingEngine.purchaseRecommendedUpgrade(commandID: purchaseID, in: &state)

        XCTAssertEqual(
            OnboardingEngine.completeDemo(at: start.addingTimeInterval(180), receiptID: UUID(), in: &state),
            .alreadyRewarded
        )
        XCTAssertEqual(
            OnboardingEngine.purchaseRecommendedUpgrade(commandID: purchaseID, in: &state),
            .duplicate
        )
        XCTAssertEqual(state.equipment.drill, 2)
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
