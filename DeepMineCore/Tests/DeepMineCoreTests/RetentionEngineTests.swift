import Foundation
import XCTest
@testable import DeepMineCore

final class RetentionEngineTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let utc = TimeZone(secondsFromGMT: 0)!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - Crew

    func testCrewGrowsEveryFiveDrillLevelsAndCapsAtTwelve() {
        XCTAssertEqual(MineCrew.size(drillLevel: 1), 1)
        XCTAssertEqual(MineCrew.size(drillLevel: 5), 1)
        XCTAssertEqual(MineCrew.size(drillLevel: 6), 2)
        XCTAssertEqual(MineCrew.size(drillLevel: 30), 6)
        XCTAssertEqual(MineCrew.size(drillLevel: 56), 12)
        XCTAssertEqual(MineCrew.size(drillLevel: Balance.maximumEquipmentLevel), 12)
        XCTAssertEqual(MineCrew.size(drillLevel: 0), 1, "Guards against invalid input")
    }

    func testCrewNextGrowthLevelStopsWhenFull() {
        XCTAssertEqual(MineCrew.nextGrowthDrillLevel(drillLevel: 1), 6)
        XCTAssertEqual(MineCrew.nextGrowthDrillLevel(drillLevel: 6), 11)
        XCTAssertNil(MineCrew.nextGrowthDrillLevel(drillLevel: 56))
    }

    /// The crew is presentation only. If it ever reaches a reward formula this fails.
    func testCrewSizeDoesNotAffectReward() throws {
        let lowCrew = EquipmentLevels(drill: 5, cart: 1, lamp: 1)
        let highCrew = EquipmentLevels(drill: 6, cart: 1, lamp: 1)
        XCTAssertEqual(MineCrew.size(drillLevel: 5), 1)
        XCTAssertEqual(MineCrew.size(drillLevel: 6), 2)
        let low = try RewardCalculator.calculate(input(equipment: lowCrew)).ore
        let high = try RewardCalculator.calculate(input(equipment: highCrew)).ore
        // The gap must be exactly the drill step, with no crew term added on top.
        XCTAssertEqual(high / low, Balance.drillRewardGrowthRate, accuracy: 1e-9)
    }

    // MARK: - Next steps

    func testNextStepsAreNearestFirstAndCapped() {
        let state = PlayerState(
            resources: Resources(ore: 50),
            equipment: EquipmentLevels(drill: 3, cart: 1, lamp: 1),
            lifetimeFocusCredits: 4,
            streakDays: 2
        )
        let steps = NextStepPlanner.steps(for: state, expectedOrePerSession: 300)
        XCTAssertLessThanOrEqual(steps.count, NextStepPlanner.maximumSteps)
        XCTAssertEqual(steps.first?.kind, .equipment)
        XCTAssertTrue(steps.contains { $0.kind == .region })
        XCTAssertTrue(steps.contains { $0.kind == .streak })
    }

    func testEquipmentStepEstimatesSessionsFromExpectedOre() {
        let state = PlayerState(
            resources: Resources(ore: 0),
            equipment: EquipmentLevels(drill: 1, cart: 1, lamp: 1),
            lifetimeFocusCredits: 4
        )
        let steps = NextStepPlanner.steps(for: state, expectedOrePerSession: 40)
        let equipment = steps.first { $0.kind == .equipment }
        // Drill level 2 costs 100; at 40 ore per session that is three sessions.
        XCTAssertEqual(equipment?.target, 100)
        XCTAssertEqual(equipment?.remainingSessions, 3)
    }

    func testEquipmentStepReportsNoEstimateWhenOreRateIsUnknown() {
        let state = PlayerState(resources: Resources(ore: 0), lifetimeFocusCredits: 4)
        let steps = NextStepPlanner.steps(for: state, expectedOrePerSession: 0)
        XCTAssertNil(steps.first { $0.kind == .equipment }?.remainingSessions)
    }

    func testStreakStepDisappearsAtTopTierAndRegionAtDeepest() {
        // Depth now comes from broken rock, not focus credits, so "deepest" has to be
        // expressed as a segment index past the abyss gate.
        let abyssIndex = ProgressionEngine.segmentIndex(forDepth: Balance.abyssRegionDepth)
        let maxed = PlayerState(
            lifetimeFocusCredits: 400,
            streakDays: 30,
            mineFace: MineFaceState(segmentIndex: abyssIndex)
        )
        let steps = NextStepPlanner.steps(for: maxed, expectedOrePerSession: 1_000)
        XCTAssertFalse(steps.contains { $0.kind == .streak })
        XCTAssertFalse(steps.contains { $0.kind == .region })
    }

    func testRegionThresholdsAdvanceWithDepth() {
        XCTAssertEqual(WorldProgression.nextRegionThreshold(afterDepth: 0)?.region, .crystal)
        XCTAssertEqual(WorldProgression.nextRegionThreshold(afterDepth: 200)?.region, .ruins)
        XCTAssertEqual(WorldProgression.nextRegionThreshold(afterDepth: 600)?.region, .abyss)
        XCTAssertNil(WorldProgression.nextRegionThreshold(afterDepth: 5_000))
    }

    // MARK: - Growth ledger

    func testGrowthLedgerIsolatesPowerFromEffort() {
        // Same session count each week, rising ore: the multiplier must reflect power.
        let old = (0..<4).map { historyEntry(weeksAgo: 8, ore: 100, index: $0) }
        let recent = (0..<4).map { historyEntry(weeksAgo: 0, ore: 400, index: 10 + $0) }
        let state = PlayerState(history: old + recent)
        let ledger = GrowthLedgerEngine.summarize(
            state, referenceDate: now, calendar: calendar, timeZone: utc
        )
        XCTAssertEqual(ledger.currentOrePerSession, 400, accuracy: 1e-9)
        XCTAssertEqual(ledger.multiplierSinceOldestWeek ?? 0, 4, accuracy: 1e-9)
        XCTAssertEqual(ledger.weeks.count, GrowthLedgerEngine.trackedWeeks)
        XCTAssertEqual(ledger.weeks.last?.weeksAgo, 0)
    }

    func testGrowthLedgerWithdrawsTheMultiplierWhenHistoryIsOneWeek() {
        let state = PlayerState(history: (0..<3).map { historyEntry(weeksAgo: 0, ore: 200, index: $0) })
        let ledger = GrowthLedgerEngine.summarize(
            state, referenceDate: now, calendar: calendar, timeZone: utc
        )
        XCTAssertNil(ledger.multiplierSinceOldestWeek)
        XCTAssertEqual(ledger.currentOrePerSession, 200, accuracy: 1e-9)
    }

    func testGrowthLedgerIgnoresAbandonedSessions() {
        let state = PlayerState(history: [
            historyEntry(weeksAgo: 0, ore: 400, index: 0),
            historyEntry(weeksAgo: 0, ore: 0, index: 1, completed: false)
        ])
        let ledger = GrowthLedgerEngine.summarize(
            state, referenceDate: now, calendar: calendar, timeZone: utc
        )
        XCTAssertEqual(ledger.currentOrePerSession, 400, accuracy: 1e-9)
    }

    // MARK: - Vein codex

    func testCodexCountsDiscoveriesAndKeepsEarliestDate() {
        let first = historyEntry(weeksAgo: 6, ore: 100, index: 0, vein: .blue)
        let later = historyEntry(weeksAgo: 1, ore: 100, index: 1, vein: .blue)
        let codex = VeinCodexEngine.summarize(PlayerState(history: [later, first]))
        let blue = codex.entries.first { $0.kind == .blue }
        XCTAssertEqual(blue?.discoveries, 2)
        XCTAssertEqual(blue?.firstFoundAt, first.endedAt)
        XCTAssertEqual(codex.totalCount, VeinKind.allCases.count)
        XCTAssertEqual(codex.discoveredCount, 1)
    }

    func testCodexListsEveryKindEvenWhenUndiscovered() {
        let codex = VeinCodexEngine.summarize(PlayerState())
        XCTAssertEqual(codex.entries.map(\.kind), VeinKind.allCases)
        XCTAssertTrue(codex.entries.allSatisfy { !$0.isDiscovered })
        XCTAssertEqual(codex.discoveredCount, 0)
    }

    // MARK: - Helpers

    private func input(equipment: EquipmentLevels) -> RewardInput {
        RewardInput(
            completionID: UUID(), outcome: .completed, sessionLength: .minutes25,
            plan: .safe, verificationGrade: .sealed, growthFocusCredits: 0,
            streakDays: 1, dailySessionNumber: 1, equipment: equipment,
            vein: nil, resonanceBoostActive: false
        )
    }

    private func historyEntry(
        weeksAgo: Int,
        ore: Double,
        index: Int,
        vein: VeinKind? = nil,
        completed: Bool = true
    ) -> SessionHistoryEntry {
        let endedAt = now.addingTimeInterval(-Double(weeksAgo) * 7 * 86_400 - Double(index) * 60)
        return SessionHistoryEntry(
            completionID: UUID(), endedAt: endedAt, focusedMinutes: 25, focusCredits: 1,
            plan: .safe, verificationGrade: .sealed, oreEarned: ore, vein: vein,
            depthAfter: 100, completed: completed
        )
    }
}
