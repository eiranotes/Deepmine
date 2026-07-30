import DeepMineCore

extension DailyRecordEntity {
    func apply(_ record: DailyRecord, sortIndex: Int) {
        focusedMinutes = record.focusedMinutes
        goalMinutes = record.goalMinutes
        sessionCount = record.sessionCount
        goalEarned = record.goalEarned
        streakApplied = record.streakApplied
        wasRestDay = record.wasRestDay
        isFinalized = record.isFinalized
        self.sortIndex = sortIndex
    }

    func coreRecord() -> DailyRecord {
        DailyRecord(
            dayKey: DayKey(year: year, month: month, day: day),
            focusedMinutes: focusedMinutes,
            goalMinutes: goalMinutes,
            sessionCount: sessionCount,
            goalEarned: goalEarned,
            streakApplied: streakApplied,
            wasRestDay: wasRestDay,
            isFinalized: isFinalized
        )
    }
}
