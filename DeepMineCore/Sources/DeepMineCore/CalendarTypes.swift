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
