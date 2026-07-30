import Foundation

/// Calendar arithmetic and record bookkeeping behind the streak rules.
extension StreakEngine {
    static func isValidDailyGoal(_ minutes: Int) -> Bool {
        (Balance.minimumDailyGoalMinutes...Balance.maximumDailyGoalMinutes).contains(minutes)
            && minutes.isMultiple(of: Balance.dailyGoalStepMinutes)
    }

    static func localDate(
        for key: DayKey,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> Date {
        var local = calendar
        local.timeZone = timeZone
        let components = DateComponents(
            timeZone: timeZone,
            year: key.year,
            month: key.month,
            day: key.day,
            hour: 12
        )
        guard let value = local.date(from: components) else {
            throw StreakError.invalidCalendarDay
        }
        return value
    }

    static func finalize(
        day: DayKey,
        in state: inout PlayerState,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> (rest: Int, penalty: Int) {
        let index = self.index(of: day, in: &state)
        guard !state.dailyRecords[index].isFinalized else { return (0, 0) }
        state.dailyRecords[index].isFinalized = true
        guard !state.dailyRecords[index].goalEarned else { return (0, 0) }

        let week = try isoWeek(for: day, calendar: calendar, timeZone: timeZone)
        if state.usedRestWeeks.insert(week).inserted {
            state.dailyRecords[index].wasRestDay = true
            return (1, 0)
        }
        return (0, 1)
    }

    static func isoWeek(
        for day: DayKey,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> ISOWeekKey {
        let value = try localDate(for: day, calendar: calendar, timeZone: timeZone)
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = timeZone
        let components = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: value)
        guard let year = components.yearForWeekOfYear,
              let week = components.weekOfYear else { throw StreakError.invalidCalendarDay }
        return ISOWeekKey(yearForWeekOfYear: year, weekOfYear: week)
    }

    /// Finds or creates the day's record, trimming the oldest days so a multi-year
    /// player does not re-encode an unbounded array on every save.
    static func index(of day: DayKey, in state: inout PlayerState) -> Int {
        if let existing = state.dailyRecords.firstIndex(where: { $0.dayKey == day }) {
            return existing
        }
        if state.dailyRecords.count >= Balance.dailyRecordLimit {
            state.dailyRecords.removeFirst(
                state.dailyRecords.count - Balance.dailyRecordLimit + 1
            )
        }
        state.dailyRecords.append(emptyRecord(day: day, goal: state.dailyGoalMinutes))
        return state.dailyRecords.index(before: state.dailyRecords.endIndex)
    }

    static func emptyRecord(day: DayKey, goal: Int) -> DailyRecord {
        DailyRecord(
            dayKey: day,
            focusedMinutes: 0,
            goalMinutes: goal,
            sessionCount: 0,
            goalEarned: false,
            streakApplied: false,
            wasRestDay: false,
            isFinalized: false
        )
    }

    static func add(focusedMinutes: Int, to record: inout DailyRecord) {
        if record.focusedMinutes > Int.max - focusedMinutes {
            record.focusedMinutes = Int.max
        } else {
            record.focusedMinutes += focusedMinutes
        }
        if record.sessionCount < Int.max { record.sessionCount += 1 }
    }
}
