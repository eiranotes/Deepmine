import Foundation
import XCTest
@testable import DeepMineCore

final class StreakEngineTests: XCTestCase {
    private let seoul = TimeZone(identifier: "Asia/Seoul")!
    private let utc = TimeZone(secondsFromGMT: 0)!
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    func testDailyGoalConfigurationBoundariesAndStep() throws {
        var state = PlayerState()
        XCTAssertEqual(state.dailyGoalMinutes, 100)
        try StreakEngine.configureDailyGoal(minutes: 25, in: &state)
        XCTAssertEqual(state.dailyGoalMinutes, 25)
        try StreakEngine.configureDailyGoal(minutes: 360, in: &state)
        XCTAssertEqual(state.dailyGoalMinutes, 360)

        XCTAssertThrowsError(try StreakEngine.configureDailyGoal(minutes: 20, in: &state))
        XCTAssertThrowsError(try StreakEngine.configureDailyGoal(minutes: 365, in: &state))
        XCTAssertThrowsError(try StreakEngine.configureDailyGoal(minutes: 26, in: &state))
    }

    func testSameDaySessionsEarnGoalAndStreakOnlyOnce() throws {
        var state = PlayerState(dailyGoalMinutes: 25)
        let day = date(2026, 7, 29, 9, 0, timeZone: seoul)

        let first = try record(15, at: day, state: &state)
        XCTAssertFalse(first.goalEarnedNow)
        XCTAssertEqual(first.totalFocusedMinutes, 15)
        XCTAssertEqual(state.streakDays, 0)

        let second = try record(10, at: day.addingTimeInterval(60), state: &state)
        XCTAssertTrue(second.goalEarnedNow)
        XCTAssertEqual(state.streakDays, 1)

        let third = try record(50, at: day.addingTimeInterval(120), state: &state)
        XCTAssertFalse(third.goalEarnedNow)
        XCTAssertEqual(third.totalFocusedMinutes, 75)
        XCTAssertEqual(state.streakDays, 1)
        XCTAssertEqual(state.dailyRecords.first?.sessionCount, 3)
    }

    func testMultipleMissedDaysConsumeOneRestThenHalveOnce() throws {
        var state = PlayerState(dailyGoalMinutes: 25, streakDays: 6)
        let monday = date(2026, 7, 27, 9, 0, timeZone: seoul)
        try record(25, at: monday, state: &state)
        XCTAssertEqual(state.streakDays, 7)

        let friday = date(2026, 7, 31, 9, 0, timeZone: seoul)
        let update = try record(0, at: friday, state: &state)

        XCTAssertEqual(update.restDaysConsumed, 1)
        XCTAssertEqual(update.penalizedMisses, 2)
        // One decay for the absence, not one per missed day.
        XCTAssertEqual(state.streakDays, 3)
        XCTAssertEqual(state.dailyRecords.filter(\.wasRestDay).count, 1)
        XCTAssertEqual(state.dailyRecords.filter { $0.isFinalized && !$0.wasRestDay && !$0.goalEarned }.count, 2)
    }

    func testEachISOWeekProvidesOneAutomaticRestDay() throws {
        var state = PlayerState(dailyGoalMinutes: 25, streakDays: 6)
        let saturday = date(2026, 8, 1, 9, 0, timeZone: seoul)
        try record(25, at: saturday, state: &state)
        let tuesday = date(2026, 8, 4, 9, 0, timeZone: seoul)

        let update = try record(0, at: tuesday, state: &state)
        XCTAssertEqual(update.restDaysConsumed, 2)
        XCTAssertEqual(update.penalizedMisses, 0)
        XCTAssertEqual(state.streakDays, 7)
        XCTAssertEqual(state.usedRestWeeks.count, 2)
    }

    func testMidnightCreatesANewDayAndFinalizesPreviousMiss() throws {
        var state = PlayerState(dailyGoalMinutes: 25)
        let beforeMidnight = date(2026, 7, 29, 23, 59, timeZone: seoul)
        try record(24, at: beforeMidnight, state: &state)

        let afterMidnight = date(2026, 7, 30, 0, 1, timeZone: seoul)
        let firstNewDay = try record(1, at: afterMidnight, state: &state)
        XCTAssertEqual(firstNewDay.restDaysConsumed, 1)
        XCTAssertEqual(state.dailyRecords.count, 2)
        XCTAssertEqual(state.streakDays, 0)

        let earned = try record(24, at: afterMidnight.addingTimeInterval(60), state: &state)
        XCTAssertTrue(earned.goalEarnedNow)
        XCTAssertEqual(state.streakDays, 1)
    }

    func testBackwardTimezoneRemapUpdatesHistoryWithoutChangingStreak() throws {
        var state = PlayerState(dailyGoalMinutes: 25)
        let instant = date(2026, 1, 1, 0, 30, timeZone: utc)
        try record(25, at: instant, state: &state, timeZone: utc)
        let latest = state.latestDayKey
        XCTAssertEqual(state.streakDays, 1)

        let historical = try record(25, at: instant, state: &state, timeZone: losAngeles)
        XCTAssertTrue(historical.wasHistorical)
        XCTAssertTrue(historical.goalEarnedNow)
        XCTAssertEqual(state.streakDays, 1)
        XCTAssertEqual(state.latestDayKey, latest)
        XCTAssertEqual(state.dailyRecords.count, 2)
        XCTAssertEqual(state.dailyRecords.filter(\.streakApplied).count, 1)
    }

    func testForwardTimezoneRemapFollowsNormalLocalDayProgression() throws {
        var state = PlayerState(dailyGoalMinutes: 25)
        let instant = date(2026, 1, 1, 0, 30, timeZone: utc)
        try record(25, at: instant, state: &state, timeZone: losAngeles)

        let forward = try record(25, at: instant, state: &state, timeZone: utc)
        XCTAssertFalse(forward.wasHistorical)
        XCTAssertEqual(forward.restDaysConsumed, 0)
        XCTAssertEqual(forward.penalizedMisses, 0)
        XCTAssertEqual(state.streakDays, 2)
        XCTAssertEqual(state.dailyRecords.count, 2)
    }

    func testDeepAbandonmentNeverRollsBackEarnedGoalOrStreak() throws {
        var state = PlayerState(dailyGoalMinutes: 100)
        let day = date(2026, 7, 29, 9, 0, timeZone: seoul)
        try record(100, at: day, state: &state)
        XCTAssertEqual(state.streakDays, 1)

        let update = try record(
            50, at: day.addingTimeInterval(60), state: &state,
            plan: .deep, outcome: .abandoned(elapsedMinutes: 50)
        )
        XCTAssertFalse(update.goalEarnedNow)
        XCTAssertEqual(update.totalFocusedMinutes, 150)
        XCTAssertEqual(state.streakDays, 1)
        XCTAssertTrue(state.dailyRecords[0].goalEarned)
    }

    func testStreakMultiplierBoundaries() {
        let examples: [(Int, Double)] = [
            (0, 1), (1, 1), (2, 1), (3, 1.10), (6, 1.10),
            (7, 1.25), (13, 1.25), (14, 1.40), (29, 1.40), (30, 1.60)
        ]
        for (days, multiplier) in examples {
            XCTAssertEqual(StreakEngine.multiplier(for: days), multiplier)
        }
    }

    func testDailyStateCodableRoundTrip() throws {
        var state = PlayerState(dailyGoalMinutes: 25)
        try record(25, at: date(2026, 7, 29, 9, 0, timeZone: seoul), state: &state)
        try record(0, at: date(2026, 7, 31, 9, 0, timeZone: seoul), state: &state)

        let data = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(PlayerState.self, from: data), state)
    }

    @discardableResult
    private func record(
        _ minutes: Int,
        at date: Date,
        state: inout PlayerState,
        timeZone: TimeZone? = nil,
        plan: MinePlan = .safe,
        outcome: SessionOutcome = .completed
    ) throws -> DailySessionUpdate {
        try StreakEngine.recordSession(
            focusedMinutes: minutes, at: date, plan: plan, outcome: outcome,
            in: &state, calendar: Calendar(identifier: .gregorian),
            timeZone: timeZone ?? seoul
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(
            timeZone: timeZone, year: year, month: month, day: day,
            hour: hour, minute: minute
        ))!
    }
}
