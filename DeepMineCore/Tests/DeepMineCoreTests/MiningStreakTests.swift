import Foundation
import XCTest
@testable import DeepMineCore

final class MiningStreakTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let seoul = TimeZone(identifier: "Asia/Seoul")!

    func testConsecutiveDaysGrowTheStreak() throws {
        var state = PlayerState()
        for day in 1...4 {
            let update = try MiningStreak.record(
                at: date(2026, 8, day), in: &state, calendar: calendar, timeZone: seoul
            )
            XCTAssertEqual(update.streakDays, day)
            XCTAssertTrue(update.grewToday)
            XCTAssertFalse(update.wasBroken)
        }
    }

    func testSecondSessionOnTheSameDayDoesNotGrowIt() throws {
        var state = PlayerState()
        try MiningStreak.record(
            at: date(2026, 8, 1, hour: 9), in: &state, calendar: calendar, timeZone: seoul
        )
        let again = try MiningStreak.record(
            at: date(2026, 8, 1, hour: 21), in: &state, calendar: calendar, timeZone: seoul
        )
        XCTAssertEqual(again.streakDays, 1)
        XCTAssertFalse(again.grewToday)
    }

    /// One skipped day is forgiven so a single busy day does not erase a month.
    func testOneMissedDayIsForgiven() throws {
        var state = PlayerState()
        try MiningStreak.record(
            at: date(2026, 8, 1), in: &state, calendar: calendar, timeZone: seoul
        )
        try MiningStreak.record(
            at: date(2026, 8, 2), in: &state, calendar: calendar, timeZone: seoul
        )
        let afterGap = try MiningStreak.record(
            at: date(2026, 8, 4), in: &state, calendar: calendar, timeZone: seoul
        )
        XCTAssertEqual(afterGap.streakDays, 3)
        XCTAssertFalse(afterGap.wasBroken)
    }

    func testTwoMissedDaysBreakItToOne() throws {
        var state = PlayerState()
        try MiningStreak.record(
            at: date(2026, 8, 1), in: &state, calendar: calendar, timeZone: seoul
        )
        let afterGap = try MiningStreak.record(
            at: date(2026, 8, 5), in: &state, calendar: calendar, timeZone: seoul
        )
        XCTAssertEqual(afterGap.streakDays, 1)
        XCTAssertTrue(afterGap.wasBroken)
    }

    /// A device clock moved backwards must neither grow nor reset the streak.
    func testBackwardsClockHoldsTheStreak() throws {
        var state = PlayerState()
        try MiningStreak.record(
            at: date(2026, 8, 10), in: &state, calendar: calendar, timeZone: seoul
        )
        try MiningStreak.record(
            at: date(2026, 8, 11), in: &state, calendar: calendar, timeZone: seoul
        )
        let backwards = try MiningStreak.record(
            at: date(2026, 8, 3), in: &state, calendar: calendar, timeZone: seoul
        )
        XCTAssertEqual(backwards.streakDays, 2)
        XCTAssertFalse(backwards.grewToday)
        XCTAssertFalse(backwards.wasBroken)
    }

    func testMultiplierMatchesTheSharedTiers() {
        XCTAssertEqual(MiningStreak.multiplier(days: 1), 1.0)
        XCTAssertEqual(MiningStreak.multiplier(days: 7), Balance.streakSevenMultiplier)
        XCTAssertEqual(MiningStreak.multiplier(days: 30), Balance.streakThirtyMultiplier)
        XCTAssertEqual(MiningStreak.multiplier(days: -5), 1.0)
    }

    /// The daily-order multiplier and the mining-days achievements both read the daily
    /// record, so recording a run has to keep writing it.
    func testRecordingKeepsTheDailyRecordForOtherSystems() throws {
        var state = PlayerState()
        try MiningStreak.record(
            at: date(2026, 8, 1, hour: 9), in: &state, calendar: calendar, timeZone: seoul
        )
        try MiningStreak.record(
            at: date(2026, 8, 1, hour: 20), in: &state, calendar: calendar, timeZone: seoul
        )
        XCTAssertEqual(state.dailyRecords.count, 1)
        XCTAssertEqual(state.dailyRecords.first?.sessionCount, 2)

        try MiningStreak.record(
            at: date(2026, 8, 2), in: &state, calendar: calendar, timeZone: seoul
        )
        XCTAssertEqual(state.dailyRecords.count, 2)
        XCTAssertEqual(state.dailyRecords.last?.sessionCount, 1)
    }

    func testDailyRecordsStayCapped() throws {
        var state = PlayerState()
        var day = date(2024, 1, 1)
        for _ in 0..<(Balance.dailyRecordLimit + 40) {
            try MiningStreak.record(at: day, in: &state, calendar: calendar, timeZone: seoul)
            day = day.addingTimeInterval(86_400)
        }
        XCTAssertLessThanOrEqual(state.dailyRecords.count, Balance.dailyRecordLimit)
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var local = calendar
        local.timeZone = seoul
        return local.date(from: DateComponents(
            timeZone: seoul, year: y, month: m, day: d, hour: hour
        ))!
    }
}
