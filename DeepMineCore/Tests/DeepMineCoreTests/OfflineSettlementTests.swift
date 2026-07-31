import XCTest
@testable import DeepMineCore

final class OfflineSettlementTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func player(cart: Int = 16) -> PlayerState {
        PlayerState(equipment: EquipmentLevels(cart: cart))
    }

    func testFirstLaunchSettlesNothingButRecordsTheMoment() {
        var state = player()
        let result = MiningLoop.settleOffline(since: nil, now: start, in: &state)
        XCTAssertEqual(result, .none)
        XCTAssertEqual(state.lastSettledAt, start)
        XCTAssertEqual(state.resources.ore, 0)
    }

    func testAwayTimeProducesOre() {
        var state = player()
        let result = MiningLoop.settleOffline(
            since: start, now: start.addingTimeInterval(3_600), in: &state
        )
        XCTAssertFalse(result.wasRejected)
        XCTAssertGreaterThan(result.segmentsBroken, 0)
        XCTAssertGreaterThan(state.resources.ore, 0)
        XCTAssertTrue(result.isWorthReporting)
    }

    func testOfflinePaysLessThanBeingPresent() {
        var offline = player()
        var present = player()
        MiningLoop.settleOffline(
            since: start, now: start.addingTimeInterval(1_800), in: &offline
        )
        MiningLoop.advance(seconds: 1_800, in: &present)
        XCTAssertLessThan(offline.resources.ore, present.resources.ore)
    }

    func testCreditedTimeIsCappedAndReported() {
        var state = player()
        let cap = Balance.maximumOfflineHours * 3_600
        let result = MiningLoop.settleOffline(
            since: start, now: start.addingTimeInterval(cap * 3), in: &state
        )
        XCTAssertTrue(result.wasCapped)
        XCTAssertEqual(result.creditedSeconds, cap * Balance.offlineEfficiency, accuracy: 1e-6)
        XCTAssertEqual(result.elapsedSeconds, cap * 3, accuracy: 1e-6)
    }

    func testExactlyAtTheCapIsNotReportedAsCapped() {
        var state = player()
        let cap = Balance.maximumOfflineHours * 3_600
        let result = MiningLoop.settleOffline(
            since: start, now: start.addingTimeInterval(cap), in: &state
        )
        XCTAssertFalse(result.wasCapped)
    }

    /// Moving the device clock must never beat playing the game.
    func testBackwardsClockPaysNothing() {
        var state = player()
        let result = MiningLoop.settleOffline(
            since: start, now: start.addingTimeInterval(-10_000), in: &state
        )
        XCTAssertTrue(result.wasRejected)
        XCTAssertEqual(state.resources.ore, 0)
        XCTAssertFalse(result.isWorthReporting)
    }

    func testAbsurdFutureTimestampPaysNothing() {
        var state = player()
        let result = MiningLoop.settleOffline(
            since: start,
            now: start.addingTimeInterval(Balance.maximumPlausibleOfflineSeconds * 2),
            in: &state
        )
        XCTAssertTrue(result.wasRejected)
        XCTAssertEqual(state.resources.ore, 0)
    }

    func testRejectedSettlementStillAdvancesTheClock() {
        var state = player()
        let now = start.addingTimeInterval(-10_000)
        MiningLoop.settleOffline(since: start, now: now, in: &state)
        // Otherwise a backwards clock would leave the mine permanently unsettleable.
        XCTAssertEqual(state.lastSettledAt, now)
    }

    func testWithoutMachineryThereIsNothingToCollect() {
        var state = player(cart: 1)
        let result = MiningLoop.settleOffline(
            since: start, now: start.addingTimeInterval(8 * 3_600), in: &state
        )
        XCTAssertTrue(result.isEmpty)
        XCTAssertFalse(result.isWorthReporting)
    }

    func testBriefAbsenceIsNotWorthASheet() {
        var state = player()
        let result = MiningLoop.settleOffline(
            since: start, now: start.addingTimeInterval(5), in: &state
        )
        XCTAssertFalse(result.isWorthReporting)
    }

    func testSettlementIsNotDoubleCounted() {
        var once = player()
        var twice = player()
        let end = start.addingTimeInterval(3_600)

        MiningLoop.settleOffline(since: start, now: end, in: &once)

        MiningLoop.settleOffline(since: start, now: end, in: &twice)
        MiningLoop.settleOffline(since: twice.lastSettledAt, now: end, in: &twice)

        XCTAssertEqual(once.resources.ore, twice.resources.ore)
        XCTAssertEqual(once.mineFace.segmentIndex, twice.mineFace.segmentIndex)
    }

    func testLastSettledAtSurvivesCodableRoundTrip() throws {
        var state = player()
        MiningLoop.settleOffline(since: start, now: start.addingTimeInterval(600), in: &state)
        let decoded = try JSONDecoder().decode(
            PlayerState.self, from: try JSONEncoder().encode(state)
        )
        XCTAssertEqual(decoded.lastSettledAt, state.lastSettledAt)
    }
}
