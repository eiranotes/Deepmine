import DeepMineCore
import XCTest
@testable import DeepMine

@MainActor
final class GameStoreOnboardingTests: XCTestCase {
    func testDemoPersistsRewardAndUpgradeWithoutSystemSideEffects() throws {
        let repository = FakeSessionRepository()
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        let store = GameStore(repository: repository, coordinator: system, clock: clock)
        let rewardID = UUID()
        let purchaseID = UUID()

        XCTAssertEqual(
            try store.beginOrResumeDemo().remainingSeconds,
            Int(Balance.demoDurationSeconds)
        )
        XCTAssertEqual(system.startCount, 0)
        clock.advance(seconds: Balance.demoDurationSeconds)
        XCTAssertEqual(
            try store.completeDemoIfNeeded(receiptID: rewardID),
            .rewarded(ore: Balance.demoOreGrant, vein: Balance.demoGuaranteedVein)
        )
        XCTAssertEqual(
            try store.purchaseDemoUpgrade(commandID: purchaseID),
            .purchased(equipment: .drill, newLevel: 2, cost: Balance.drillBasePrice)
        )
        XCTAssertEqual(repository.player.completedSessionCount, 0)
        XCTAssertEqual(repository.player.equipment.drill, 2)
        XCTAssertEqual(repository.player.demoRewardReceiptID, rewardID)
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
