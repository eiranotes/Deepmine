import DeepMineCore
import XCTest
@testable import DeepMine

@MainActor
final class GameStoreOnboardingTests: XCTestCase {
    func testFirstRockPersistsRewardAndUpgradeWithoutSystemSideEffects() throws {
        let repository = FakeSessionRepository()
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        let store = GameStore(repository: repository, coordinator: system, clock: clock)
        let rewardID = UUID()
        let purchaseID = UUID()

        var completion: DemoStrikeResult?
        for _ in 0..<20 {
            completion = try store.strikeOnboardingRock(receiptID: rewardID)
            if case .rewarded = completion { break }
        }
        guard case let .rewarded(update, ore, vein) = completion else {
            return XCTFail("The onboarding rock did not break")
        }
        XCTAssertTrue(update.brokeSomething)
        XCTAssertEqual(ore, Balance.demoOreGrant)
        XCTAssertEqual(vein, Balance.demoGuaranteedVein)
        XCTAssertEqual(
            try store.purchaseDemoUpgrade(commandID: purchaseID),
            .purchased(equipment: .drill, newLevel: 2, cost: Balance.drillBasePrice)
        )
        XCTAssertEqual(repository.player.completedSessionCount, 0)
        XCTAssertEqual(repository.player.equipment.drill, 2)
        XCTAssertEqual(repository.player.mineFace.segmentIndex, 1)
        XCTAssertEqual(repository.player.demoRewardReceiptID, rewardID)
        XCTAssertEqual(repository.player.onboardingStage, .complete)
        XCTAssertEqual(system.startCount, 0)
        XCTAssertEqual(system.finishCount, 0)
    }

    func testSelectionSaveFailureDoesNotChangeRepositoryState() throws {
        let repository = FakeSessionRepository()
        repository.failPlayerSave = true
        let store = GameStore(
            repository: repository,
            coordinator: FakeSystemCoordinator(),
            clock: FakeClock()
        )

        XCTAssertThrowsError(try store.select(duration: .minutes50))
        XCTAssertEqual(repository.player.lastSelectedDuration, .minutes25)
    }
}
