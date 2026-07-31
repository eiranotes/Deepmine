import Foundation

public struct MiningStreakUpdate: Equatable, Sendable {
    public let dayKey: DayKey
    public let streakDays: Int
    public let grewToday: Bool
    public let wasBroken: Bool

    public init(dayKey: DayKey, streakDays: Int, grewToday: Bool, wasBroken: Bool) {
        self.dayKey = dayKey
        self.streakDays = streakDays
        self.grewToday = grewToday
        self.wasBroken = wasBroken
    }
}

/// Consecutive days on which the player mined at all.
///
/// Replaces the focus-era `StreakEngine`, which needed a daily minute goal, weekly rest
/// grants and fractional decay because it was measuring whether a human kept a promise.
/// An idle game only needs to know whether they came back, so this is roughly a fifth of
/// the size and has one rule: mine on consecutive days.
///
/// One missed day is forgiven. That is retention design, not a fairness guardrail — the
/// removed guardrails were about limiting play, this is about not punishing a gap.
public enum MiningStreak {
    /// Days that may be skipped without losing the streak.
    public static let graceDays = 1

    public static func multiplier(days: Int) -> Double {
        Balance.streakMultiplier(days: max(0, days))
    }

    public static func dayKey(
        for date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> DayKey {
        var local = calendar
        local.timeZone = timeZone
        let components = local.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else { throw StreakError.invalidCalendarDay }
        return DayKey(year: year, month: month, day: day)
    }

    @discardableResult
    public static func record(
        at date: Date,
        in state: inout PlayerState,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> MiningStreakUpdate {
        var local = calendar
        local.timeZone = timeZone
        let today = try dayKey(for: date, calendar: local, timeZone: timeZone)

        // The daily record is still the only place "how many runs today" lives, which
        // the daily-order multiplier and the mining-days achievements both read.
        recordDay(today, in: &state)

        guard let last = state.latestDayKey else {
            state.latestDayKey = today
            state.streakDays = 1
            return MiningStreakUpdate(
                dayKey: today, streakDays: 1, grewToday: true, wasBroken: false
            )
        }
        guard last != today else {
            return MiningStreakUpdate(
                dayKey: today,
                streakDays: state.streakDays,
                grewToday: false,
                wasBroken: false
            )
        }

        let gap = try elapsedDays(from: last, to: today, calendar: local, timeZone: timeZone)
        // A negative gap means the device clock moved backwards. Hold the streak rather
        // than rewarding or punishing it.
        guard gap > 0 else {
            return MiningStreakUpdate(
                dayKey: last,
                streakDays: state.streakDays,
                grewToday: false,
                wasBroken: false
            )
        }

        let broken = gap > graceDays + 1
        state.streakDays = broken ? 1 : state.streakDays + 1
        state.latestDayKey = today
        return MiningStreakUpdate(
            dayKey: today,
            streakDays: state.streakDays,
            grewToday: true,
            wasBroken: broken
        )
    }

    /// Appends or increments today's record, trimming the oldest days so a multi-year
    /// player does not re-encode an unbounded array on every save.
    private static func recordDay(_ day: DayKey, in state: inout PlayerState) {
        if let index = state.dailyRecords.firstIndex(where: { $0.dayKey == day }) {
            var record = state.dailyRecords[index]
            if record.sessionCount < Int.max { record.sessionCount += 1 }
            state.dailyRecords[index] = record
            return
        }
        if state.dailyRecords.count >= Balance.dailyRecordLimit {
            state.dailyRecords.removeFirst(
                state.dailyRecords.count - Balance.dailyRecordLimit + 1
            )
        }
        state.dailyRecords.append(DailyRecord(
            dayKey: day,
            focusedMinutes: 0,
            goalMinutes: 0,
            sessionCount: 1,
            goalEarned: false,
            streakApplied: false,
            wasRestDay: false,
            isFinalized: false
        ))
    }

    static func elapsedDays(
        from start: DayKey,
        to end: DayKey,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> Int {
        let a = try noonDate(for: start, calendar: calendar, timeZone: timeZone)
        let b = try noonDate(for: end, calendar: calendar, timeZone: timeZone)
        guard let days = calendar.dateComponents([.day], from: a, to: b).day else {
            throw StreakError.invalidCalendarDay
        }
        return days
    }

    /// Noon anchoring keeps DST transitions from shifting a day boundary.
    private static func noonDate(
        for key: DayKey,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> Date {
        var local = calendar
        local.timeZone = timeZone
        let components = DateComponents(
            timeZone: timeZone,
            year: key.year, month: key.month, day: key.day, hour: 12
        )
        guard let value = local.date(from: components) else {
            throw StreakError.invalidCalendarDay
        }
        return value
    }
}
