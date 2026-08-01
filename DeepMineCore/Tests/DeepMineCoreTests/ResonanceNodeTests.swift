import XCTest
@testable import DeepMineCore

final class ResonanceNodeTests: XCTestCase {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    private func advance(
        _ state: ResonanceNodeState,
        by seconds: TimeInterval,
        isForeground: Bool = true,
        seed: UInt64 = 7
    ) -> ResonanceNodeState {
        var generator = SeededGenerator(seed: seed)
        return ResonanceNodeEngine.advance(
            state,
            now: start.addingTimeInterval(seconds),
            isForeground: isForeground,
            using: &generator
        )
    }

    func testTheFirstNodeIsScheduledEarlyEnoughToTeachTheMechanic() throws {
        let scheduled = advance(ResonanceNodeState(), by: 0)
        let appearsAt = try XCTUnwrap(scheduled.appearsAt)
        XCTAssertEqual(
            appearsAt.timeIntervalSince(start),
            Balance.resonanceNodeFirstDelay,
            accuracy: 0.001
        )
    }

    func testLaterNodesUseTheLongRandomGap() throws {
        var state = ResonanceNodeState(phase: .waiting, cycle: 3)
        state = advance(state, by: 0)
        let delay = try XCTUnwrap(state.appearsAt).timeIntervalSince(start)
        XCTAssertGreaterThanOrEqual(delay, Balance.resonanceNodeMinimumDelay)
        XCTAssertLessThanOrEqual(delay, Balance.resonanceNodeMaximumDelay)
    }

    func testAnUnclaimedNodeExpiresIntoAMissWithNoBoost() {
        var state = advance(ResonanceNodeState(), by: 0)
        state = advance(state, by: Balance.resonanceNodeFirstDelay)
        XCTAssertEqual(state.phase, .active)

        state = advance(state, by: Balance.resonanceNodeFirstDelay + Balance.resonanceNodeActiveWindow)
        XCTAssertEqual(state.phase, .missed)
        XCTAssertFalse(state.isBoostActive(at: start.addingTimeInterval(100)))
    }

    func testClaimingAnActiveNodeDoublesOutputForTheBoostWindow() {
        var state = advance(ResonanceNodeState(), by: 0)
        state = advance(state, by: Balance.resonanceNodeFirstDelay)
        let claimAt = start.addingTimeInterval(Balance.resonanceNodeFirstDelay + 1)
        state = ResonanceNodeEngine.claim(state, now: claimAt)

        XCTAssertEqual(state.phase, .claimed)
        XCTAssertEqual(
            ResonanceNodeEngine.outputMultiplier(state, at: claimAt),
            Balance.resonanceNodeMultiplier
        )
        XCTAssertEqual(
            ResonanceNodeEngine.outputMultiplier(
                state,
                at: claimAt.addingTimeInterval(Balance.resonanceNodeBoostDuration + 0.1)
            ),
            1
        )
    }

    /// A press outside the window must never manufacture a boost.
    func testClaimingOutsideTheWindowDoesNothing() {
        for phase in [ResonanceNodePhase.waiting, .claimed, .missed] {
            let state = ResonanceNodeState(phase: phase)
            let claimed = ResonanceNodeEngine.claim(state, now: start)
            XCTAssertEqual(claimed, state, "\(phase)")
            XCTAssertFalse(claimed.isBoostActive(at: start))
        }
    }

    /// Backgrounding must not spend a node the player never had the chance to see.
    func testBackgroundingRetractsAnActiveNodeWithoutRecordingAMiss() {
        var state = advance(ResonanceNodeState(), by: 0)
        state = advance(state, by: Balance.resonanceNodeFirstDelay)
        XCTAssertEqual(state.phase, .active)

        state = advance(state, by: Balance.resonanceNodeFirstDelay + 1, isForeground: false)
        XCTAssertEqual(state.phase, .waiting)
        XCTAssertEqual(state.cycle, 0)
        XCTAssertNil(state.appearsAt)
    }

    func testBackgroundSchedulesNothing() {
        let state = advance(ResonanceNodeState(), by: 0, isForeground: false)
        XCTAssertNil(state.appearsAt)
        XCTAssertEqual(state.phase, .waiting)
    }

    /// A running boost belongs to the player, so leaving the screen does not cancel it.
    func testAClaimedBoostSurvivesBackgrounding() {
        var state = advance(ResonanceNodeState(), by: 0)
        state = advance(state, by: Balance.resonanceNodeFirstDelay)
        let claimAt = start.addingTimeInterval(Balance.resonanceNodeFirstDelay)
        state = ResonanceNodeEngine.claim(state, now: claimAt)

        let backgrounded = advance(state, by: Balance.resonanceNodeFirstDelay + 2, isForeground: false)
        XCTAssertTrue(backgrounded.isBoostActive(at: claimAt.addingTimeInterval(2)))
    }

    func testTheCycleAdvancesAfterSettlingSoNodesAlternateSides() {
        var state = advance(ResonanceNodeState(), by: 0)
        state = advance(state, by: Balance.resonanceNodeFirstDelay)
        let claimAt = Balance.resonanceNodeFirstDelay
        state = ResonanceNodeEngine.claim(state, now: start.addingTimeInterval(claimAt))
        XCTAssertTrue(state.prefersTrailingEdge)

        state = advance(state, by: claimAt + Balance.resonanceNodeSettleDelay)
        XCTAssertEqual(state.phase, .waiting)
        XCTAssertEqual(state.cycle, 1)
        XCTAssertFalse(state.prefersTrailingEdge)
    }

    /// The boost has to reach the rock, not just the label. Both damage sources double;
    /// critical odds deliberately do not.
    func testTheBoostDoublesTapAndAutomationWithoutTouchingLuck() {
        var state = PlayerState()
        state.equipment = EquipmentLevels(drill: 4, cart: 4, lamp: 4)
        let plain = MiningLoop.power(for: state)
        let boosted = plain.scaled(by: Balance.resonanceNodeMultiplier)

        XCTAssertEqual(
            boosted.tapDamage.doubleValue,
            plain.tapDamage.doubleValue * Balance.resonanceNodeMultiplier,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            boosted.damagePerSecond.doubleValue,
            plain.damagePerSecond.doubleValue * Balance.resonanceNodeMultiplier,
            accuracy: 0.0001
        )
        XCTAssertEqual(boosted.criticalChance, plain.criticalChance)
        XCTAssertEqual(boosted.criticalMultiplier, plain.criticalMultiplier)
    }

    func testAMultiplierOfOneOrLessLeavesPowerUntouched() {
        var state = PlayerState()
        state.equipment = EquipmentLevels(drill: 3, cart: 3, lamp: 3)
        let plain = MiningLoop.power(for: state)
        XCTAssertEqual(plain.scaled(by: 1), plain)
        XCTAssertEqual(plain.scaled(by: 0), plain)
        XCTAssertEqual(plain.scaled(by: .nan), plain)
    }

    /// Boosted automation must actually break rock faster.
    func testBoostedAutomationAdvancesTheRockFaster() {
        var plain = PlayerState()
        plain.equipment = EquipmentLevels(drill: 1, cart: 6, lamp: 1)
        var boosted = plain

        MiningLoop.advance(seconds: 3, in: &plain)
        MiningLoop.advance(
            seconds: 3,
            outputMultiplier: Balance.resonanceNodeMultiplier,
            in: &boosted
        )

        XCTAssertLessThan(boosted.mineFace.remainingIntegrity, plain.mineFace.remainingIntegrity)
    }

    func testCountdownsReadOutWholeSecondsAndStopAtZero() {
        var state = advance(ResonanceNodeState(), by: 0)
        state = advance(state, by: Balance.resonanceNodeFirstDelay)
        let now = start.addingTimeInterval(Balance.resonanceNodeFirstDelay)
        XCTAssertEqual(state.secondsRemaining(at: now), Int(Balance.resonanceNodeActiveWindow))
        XCTAssertEqual(
            state.secondsRemaining(at: now.addingTimeInterval(Balance.resonanceNodeActiveWindow + 5)),
            0
        )
        XCTAssertEqual(ResonanceNodeState().secondsRemaining(at: now), 0)
    }
}
