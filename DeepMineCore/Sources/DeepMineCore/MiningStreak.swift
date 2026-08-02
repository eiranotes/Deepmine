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

public enum MiningStreak {
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

    /// Records a day on which the mine actually advanced. Session completion passes
    /// `incrementSessionCount: true`; taps and offline production pass false so breaking
    /// several rocks in one day cannot masquerade as several focus sessions.
    @discardableResult
    public static func record(
        at date: Date,
        in state: inout PlayerState,
        calendar: Calendar,
        timeZone: TimeZone,
        incrementSessionCount: Bool = true
    ) throws -> MiningStreakUpdate {
        var local = calendar
        local.timeZone = timeZone
        let today = try dayKey(for: date, calendar: local, timeZone: timeZone)
        recordDay(today, incrementSessionCount: incrementSessionCount, in: &state)

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

    private static func recordDay(
        _ day: DayKey,
        incrementSessionCount: Bool,
        in state: inout PlayerState
    ) {
        if let index = state.dailyRecords.firstIndex(where: { $0.dayKey == day }) {
            guard incrementSessionCount else { return }
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
            sessionCount: incrementSessionCount ? 1 : 0,
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

    static func noonDate(
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
