import Foundation

public struct DayKey: Codable, Equatable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
}

public struct ISOWeekKey: Codable, Equatable, Hashable, Sendable {
    public let yearForWeekOfYear: Int
    public let weekOfYear: Int

    public init(yearForWeekOfYear: Int, weekOfYear: Int) {
        self.yearForWeekOfYear = yearForWeekOfYear
        self.weekOfYear = weekOfYear
    }
}

public struct DailyRecord: Codable, Equatable, Sendable {
    public let dayKey: DayKey
    public var focusedMinutes: Int
    public let goalMinutes: Int
    public var sessionCount: Int
    public var goalEarned: Bool
    public var streakApplied: Bool
    public var wasRestDay: Bool
    public var isFinalized: Bool

    public init(
        dayKey: DayKey,
        focusedMinutes: Int,
        goalMinutes: Int,
        sessionCount: Int,
        goalEarned: Bool,
        streakApplied: Bool,
        wasRestDay: Bool,
        isFinalized: Bool
    ) {
        self.dayKey = dayKey
        self.focusedMinutes = focusedMinutes
        self.goalMinutes = goalMinutes
        self.sessionCount = sessionCount
        self.goalEarned = goalEarned
        self.streakApplied = streakApplied
        self.wasRestDay = wasRestDay
        self.isFinalized = isFinalized
    }
}

public struct DailySessionUpdate: Codable, Equatable, Sendable {
    public let dayKey: DayKey
    public let totalFocusedMinutes: Int
    public let goalEarnedNow: Bool
    public let streakDays: Int
    public let restDaysConsumed: Int
    public let penalizedMisses: Int
    public let wasHistorical: Bool

    public init(
        dayKey: DayKey,
        totalFocusedMinutes: Int,
        goalEarnedNow: Bool,
        streakDays: Int,
        restDaysConsumed: Int,
        penalizedMisses: Int,
        wasHistorical: Bool
    ) {
        self.dayKey = dayKey
        self.totalFocusedMinutes = totalFocusedMinutes
        self.goalEarnedNow = goalEarnedNow
        self.streakDays = streakDays
        self.restDaysConsumed = restDaysConsumed
        self.penalizedMisses = penalizedMisses
        self.wasHistorical = wasHistorical
    }
}

public struct StreakSettlement: Codable, Equatable, Sendable {
    public let restDaysConsumed: Int
    public let penalizedMisses: Int
    public let wasHistorical: Bool

    public init(restDaysConsumed: Int, penalizedMisses: Int, wasHistorical: Bool) {
        self.restDaysConsumed = restDaysConsumed
        self.penalizedMisses = penalizedMisses
        self.wasHistorical = wasHistorical
    }
}

public enum StreakError: Error, Codable, Equatable, Sendable {
    case invalidDailyGoal
    case invalidFocusedMinutes
    case invalidCalendarDay
}

public enum StreakEngine {
    public static func configureDailyGoal(
        minutes: Int,
        in state: inout PlayerState
    ) throws {
        guard isValidDailyGoal(minutes) else { throw StreakError.invalidDailyGoal }
        state.dailyGoalMinutes = minutes
    }

    public static func multiplier(for streakDays: Int) -> Double {
        Balance.streakMultiplier(days: max(0, streakDays))
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

    /// Closes out every day before `date` so the streak a session is rewarded with is
    /// the settled one. Callers must run this before building a `RewardInput`.
    @discardableResult
    public static func settle(
        at date: Date,
        in state: inout PlayerState,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> StreakSettlement {
        guard isValidDailyGoal(state.dailyGoalMinutes) else {
            throw StreakError.invalidDailyGoal
        }
        var local = calendar
        local.timeZone = timeZone
        let currentKey = try dayKey(for: date, calendar: local, timeZone: timeZone)
        let currentDate = try localDate(for: currentKey, calendar: local, timeZone: timeZone)
        guard let latest = state.latestDayKey else {
            state.latestDayKey = currentKey
            return StreakSettlement(restDaysConsumed: 0, penalizedMisses: 0, wasHistorical: false)
        }
        let latestDate = try localDate(for: latest, calendar: local, timeZone: timeZone)
        guard currentDate > latestDate else {
            return StreakSettlement(
                restDaysConsumed: 0,
                penalizedMisses: 0,
                wasHistorical: currentDate < latestDate
            )
        }

        var restDaysConsumed = 0
        var penalizedMisses = 0
        var cursor: Date? = latestDate
        while let day = cursor, day < currentDate {
            let key = try dayKey(for: day, calendar: local, timeZone: timeZone)
            let result = try finalize(day: key, in: &state, calendar: local, timeZone: timeZone)
            restDaysConsumed += result.rest
            penalizedMisses += result.penalty
            cursor = local.date(byAdding: .day, value: 1, to: day)
        }
        // One decay per absence, however long it lasted. Halving per missed day turned
        // a two week break into a full reset, which §7.2 rules out.
        if penalizedMisses > 0 {
            state.streakDays /= Balance.missedDayStreakDivisor
        }
        state.latestDayKey = currentKey
        return StreakSettlement(
            restDaysConsumed: restDaysConsumed,
            penalizedMisses: penalizedMisses,
            wasHistorical: false
        )
    }

    public static func recordSession(
        focusedMinutes: Int,
        at date: Date,
        plan _: MinePlan,
        outcome _: SessionOutcome,
        in state: inout PlayerState,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> DailySessionUpdate {
        guard focusedMinutes >= 0 else { throw StreakError.invalidFocusedMinutes }
        guard isValidDailyGoal(state.dailyGoalMinutes) else {
            throw StreakError.invalidDailyGoal
        }
        var local = calendar
        local.timeZone = timeZone
        let currentKey = try dayKey(for: date, calendar: local, timeZone: timeZone)
        let settlement = try settle(
            at: date,
            in: &state,
            calendar: local,
            timeZone: timeZone
        )
        let restDaysConsumed = settlement.restDaysConsumed
        let penalizedMisses = settlement.penalizedMisses
        let wasHistorical = settlement.wasHistorical

        let recordIndex = index(of: currentKey, in: &state)
        add(focusedMinutes: focusedMinutes, to: &state.dailyRecords[recordIndex])
        let earnedNow = !state.dailyRecords[recordIndex].goalEarned
            && state.dailyRecords[recordIndex].focusedMinutes >= state.dailyRecords[recordIndex].goalMinutes
        if earnedNow {
            state.dailyRecords[recordIndex].goalEarned = true
        }
        if !wasHistorical,
           !state.dailyRecords[recordIndex].isFinalized,
           state.dailyRecords[recordIndex].goalEarned,
           !state.dailyRecords[recordIndex].streakApplied {
            if state.streakDays < Int.max { state.streakDays += 1 }
            state.dailyRecords[recordIndex].streakApplied = true
        }

        return DailySessionUpdate(
            dayKey: currentKey,
            totalFocusedMinutes: state.dailyRecords[recordIndex].focusedMinutes,
            goalEarnedNow: earnedNow,
            streakDays: state.streakDays,
            restDaysConsumed: restDaysConsumed,
            penalizedMisses: penalizedMisses,
            wasHistorical: wasHistorical
        )
    }
}
