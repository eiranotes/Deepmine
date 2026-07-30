import Foundation

public struct PlanSessionCount: Codable, Equatable, Sendable {
    public let plan: MinePlan
    public let count: Int

    public init(plan: MinePlan, count: Int) {
        self.plan = plan
        self.count = count
    }
}

public struct WeeklyLedger: Codable, Equatable, Sendable {
    public let startsAt: Date
    public let endsAt: Date
    public let focusedMinutes: Int
    public let totalSessions: Int
    public let completedSessions: Int
    public let deepestReturnMeters: Int
    public let oreEarned: Double
    public let planMix: [PlanSessionCount]
    public let entries: [SessionHistoryEntry]
    public let veinHistory: [SessionHistoryEntry]

    public init(
        startsAt: Date,
        endsAt: Date,
        focusedMinutes: Int,
        totalSessions: Int,
        completedSessions: Int,
        deepestReturnMeters: Int,
        oreEarned: Double,
        planMix: [PlanSessionCount],
        entries: [SessionHistoryEntry],
        veinHistory: [SessionHistoryEntry]
    ) {
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.focusedMinutes = focusedMinutes
        self.totalSessions = totalSessions
        self.completedSessions = completedSessions
        self.deepestReturnMeters = deepestReturnMeters
        self.oreEarned = oreEarned
        self.planMix = planMix
        self.entries = entries
        self.veinHistory = veinHistory
    }
}

public enum WeeklyLedgerEngine {
    /// The ISO week a rest day would be drawn from, so the home screen can say whether
    /// this week's grace is still available.
    public static func currentISOWeek(
        for date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> ISOWeekKey {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = timeZone
        let components = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let year = components.yearForWeekOfYear,
              let week = components.weekOfYear else {
            throw StreakError.invalidCalendarDay
        }
        return ISOWeekKey(yearForWeekOfYear: year, weekOfYear: week)
    }

    public static func summarize(
        _ state: PlayerState,
        referenceDate: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> WeeklyLedger {
        var local = calendar
        local.timeZone = timeZone
        let interval = local.dateInterval(of: .weekOfYear, for: referenceDate)
            ?? DateInterval(start: referenceDate, duration: 0)
        let entries = state.history
            .filter { interval.contains($0.endedAt) }
            .sorted { $0.endedAt > $1.endedAt }
        let planMix = MinePlan.allCases.map { plan in
            PlanSessionCount(plan: plan, count: entries.count { $0.plan == plan })
        }
        return WeeklyLedger(
            startsAt: interval.start,
            endsAt: interval.end,
            focusedMinutes: saturatingMinutes(entries),
            totalSessions: entries.count,
            completedSessions: entries.count(where: \.completed),
            deepestReturnMeters: entries.map(\.depthAfter).max() ?? 0,
            oreEarned: entries.reduce(0) { $0 + $1.oreEarned },
            planMix: planMix,
            entries: entries,
            veinHistory: entries.filter { $0.vein != nil }
        )
    }

    private static func saturatingMinutes(_ entries: [SessionHistoryEntry]) -> Int {
        entries.reduce(into: 0) { total, entry in
            if total > Int.max - entry.focusedMinutes {
                total = Int.max
            } else {
                total += entry.focusedMinutes
            }
        }
    }
}
