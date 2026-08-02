import XCTest
@testable import DeepMineCore

final class MiningLoopTests: XCTestCase {
    private func player(drill: Int = 1, cart: Int = 1, lamp: Int = 1) -> PlayerState {
        PlayerState(equipment: EquipmentLevels(drill: drill, cart: cart, lamp: lamp))
    }

    // MARK: Face state

    func testFreshFaceStartsAtFullIntegrityOfTheFirstSegment() {
        let face = MineFaceState()
        XCTAssertEqual(face.segmentIndex, 0)
        XCTAssertEqual(face.remainingIntegrity, RockGenerator.segment(at: 0).maximumIntegrity)
        XCTAssertEqual(face.brokenFraction, 0, accuracy: 1e-9)
        XCTAssertEqual(face.damageStage, 1)
    }

    func testBrokenFractionTracksDamage() {
        let full = RockGenerator.segment(at: 4).maximumIntegrity
        let face = MineFaceState(segmentIndex: 4, remainingIntegrity: full * 0.25)
        XCTAssertEqual(face.brokenFraction, 0.75, accuracy: 1e-9)
    }

    // MARK: Depth is now earned by breaking rock

    func testDepthComesFromSegmentsNotFocusCredits() {
        var focusOnly = PlayerState(lifetimeFocusCredits: 5_000)
        XCTAssertEqual(focusOnly.depthMeters, 0)

        MiningLoop.advance(seconds: 0, in: &focusOnly)
        XCTAssertEqual(focusOnly.depthMeters, 0)

        let deep = PlayerState(mineFace: MineFaceState(segmentIndex: 30))
        XCTAssertEqual(deep.depthMeters, 30 * Balance.metersPerSegment)
    }

    func testLegacyBonusDepthMovesTheRealFaceInsteadOfSplittingTheDepthSource() {
        let state = PlayerState(
            bonusDepthMeters: 60,
            mineFace: MineFaceState(segmentIndex: 10)
        )
        XCTAssertEqual(state.depthMeters, 10 * Balance.metersPerSegment + 60)
        XCTAssertEqual(state.mineFace.segmentIndex, 25)
        XCTAssertEqual(state.bonusDepthMeters, 0)
        XCTAssertEqual(state.mineFace.segment, RockGenerator.segment(at: 25))
    }

    // MARK: Striking

    func testStrikeDamagesTheRockAndEventuallyBreaksIt() {
        var state = player(drill: 20)
        var generator = SeededGenerator(seed: 11)
        var broke = false
        for _ in 0..<200 {
            let update = MiningLoop.strike(using: &generator, in: &state)
            if update.brokeSomething { broke = true; break }
        }
        XCTAssertTrue(broke)
        XCTAssertGreaterThan(state.resources.ore, 0)
        XCTAssertGreaterThan(state.mineFace.segmentIndex, 0)
        XCTAssertGreaterThan(state.mineFace.lifetimeSegmentsBroken, 0)
    }

    func testOreOnlyArrivesWhenSomethingBreaks() {
        var state = player(drill: 1)
        var generator = SeededGenerator(seed: 3)
        let update = MiningLoop.strike(using: &generator, in: &state)
        XCTAssertFalse(update.brokeSomething)
        XCTAssertEqual(state.resources.ore.doubleValue, 0)
    }

    func testStrikeIsDeterministicForTheSameSeed() {
        var left = player(drill: 8, lamp: 10)
        var right = player(drill: 8, lamp: 10)
        var a = SeededGenerator(seed: 404)
        var b = SeededGenerator(seed: 404)
        for _ in 0..<80 {
            MiningLoop.strike(using: &a, in: &left)
            MiningLoop.strike(using: &b, in: &right)
        }
        XCTAssertEqual(left.mineFace, right.mineFace)
        XCTAssertEqual(left.resources.ore, right.resources.ore)
    }

    func testWeakPointIsIgnoredWhenTheSegmentHasNone() {
        // Find a segment without a weak point, then confirm claiming a hit changes nothing.
        guard let index = (0..<200).first(where: { RockGenerator.segment(at: $0).weakPoint == nil })
        else { return XCTFail("no weak-point-free segment in range") }

        var withClaim = PlayerState(
            equipment: EquipmentLevels(drill: 10),
            mineFace: MineFaceState(segmentIndex: index)
        )
        var without = withClaim
        var a = SeededGenerator(seed: 7)
        var b = SeededGenerator(seed: 7)

        let claimed = MiningLoop.strike(hitWeakPoint: true, using: &a, in: &withClaim)
        let plain = MiningLoop.strike(hitWeakPoint: false, using: &b, in: &without)
        XCTAssertEqual(claimed.damage, plain.damage)
        XCTAssertFalse(claimed.hitWeakPoint)
    }

    // MARK: Automation

    func testAutomationAdvancesTheMineWithoutTaps() {
        var state = player(cart: 18)
        let update = MiningLoop.advance(seconds: 3_600, in: &state)
        XCTAssertTrue(update.brokeSomething)
        XCTAssertGreaterThan(state.resources.ore, 0)
        XCTAssertGreaterThan(state.depthMeters, 0)
    }

    func testAutomationDoesNothingWithoutMachinery() {
        var state = player(cart: 1)
        let update = MiningLoop.advance(seconds: 86_400, in: &state)
        XCTAssertFalse(update.brokeSomething)
        XCTAssertEqual(state.resources.ore.doubleValue, 0)
        XCTAssertEqual(state.depthMeters, 0)
    }

    /// Time watched on screen must not also be billed as time away. The on-screen tick
    /// moves the settlement mark; without that, returning from the background pays for
    /// the minutes the player just spent watching the mine run.
    func testOnScreenTicksAreNotPaidAgainAsOfflineTime() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        var state = player(cart: 18)
        MiningLoop.settleOffline(since: start, now: start, in: &state)

        var watched = start
        for _ in 0..<120 {
            watched += 60
            MiningLoop.advance(seconds: 60, at: watched, in: &state)
        }
        let afterWatching = state.resources.ore

        // Returning immediately, with no time away, owes nothing.
        let settlement = MiningLoop.settleOffline(since: state.lastSettledAt, now: watched, in: &state)
        XCTAssertEqual(state.resources.ore, afterWatching)
        XCTAssertEqual(settlement.segmentsBroken, 0)
        XCTAssertTrue(settlement.oreGained.isZero)
    }

    func testVisibleTimerUsesOfflineSettlementWhenItsLocalTickIsStale() {
        let backgrounded = Date(timeIntervalSince1970: 2_000_000)
        let returned = backgrounded.addingTimeInterval(3_600)
        let firstVisibleTick = returned.addingTimeInterval(Balance.automationStepSeconds)

        XCTAssertEqual(
            MiningLoop.unsettledVisibleSeconds(
                lastTick: backgrounded,
                lastSettledAt: returned,
                now: firstVisibleTick
            ),
            Balance.automationStepSeconds,
            accuracy: 1e-9
        )
    }

    /// One long catch-up must land in the same place as many short ticks, or the offline
    /// return would pay differently from watching the same time pass on screen.
    func testOneLongAdvanceMatchesManyShortOnes() {
        var single = player(cart: 14)
        var stepped = player(cart: 14)

        MiningLoop.advance(seconds: 600, in: &single)
        for _ in 0..<600 { MiningLoop.advance(seconds: 1, in: &stepped) }

        XCTAssertEqual(single.mineFace.segmentIndex, stepped.mineFace.segmentIndex)
        XCTAssertEqual(
            single.resources.ore.doubleValue,
            stepped.resources.ore.doubleValue,
            accuracy: max(1, single.resources.ore.doubleValue * 1e-9)
        )
    }

    func testAdvanceDecaysTheImpactMeter() {
        var state = player(drill: 5)
        var generator = SeededGenerator(seed: 1)
        MiningLoop.strike(using: &generator, in: &state)
        let charged = state.mineFace.impact.value
        XCTAssertGreaterThan(charged, 0)

        MiningLoop.advance(seconds: 5, in: &state)
        XCTAssertLessThan(state.mineFace.impact.value, charged)
    }

    // MARK: Persistence

    func testFaceSurvivesCodableRoundTrip() throws {
        var state = player(drill: 12, cart: 6)
        var generator = SeededGenerator(seed: 55)
        for _ in 0..<40 { MiningLoop.strike(using: &generator, in: &state) }

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(PlayerState.self, from: data)
        XCTAssertEqual(decoded.mineFace, state.mineFace)
        XCTAssertEqual(decoded.depthMeters, state.depthMeters)
    }

    /// Pre-pivot saves have no rock face. Dropping such a player back to the surface
    /// would erase everything they had earned.
    func testLegacySaveKeepsItsDepthBySeedingTheFace() throws {
        let legacy = PlayerState(lifetimeFocusCredits: 120)
        let legacyDepth = ProgressionEngine.depth(lifetimeFocusCredits: 120)
        XCTAssertGreaterThan(legacyDepth, 0)

        var json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(legacy)
        ) as! [String: Any]
        json.removeValue(forKey: "mineFace")
        let data = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(PlayerState.self, from: data)
        XCTAssertEqual(
            decoded.mineFace.segmentIndex,
            ProgressionEngine.segmentIndex(forDepth: legacyDepth)
        )
        XCTAssertGreaterThan(decoded.depthMeters, 0)
    }
}
