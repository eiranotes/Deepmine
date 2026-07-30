import Foundation

public struct GrowthWeek: Codable, Equatable, Sendable {
    public let weeksAgo: Int
    public let completedSessions: Int
    public let orePerSession: Double

    public init(weeksAgo: Int, completedSessions: Int, orePerSession: Double) {
        self.weeksAgo = weeksAgo
        self.completedSessions = completedSessions
        self.orePerSession = orePerSession
    }
}

/// Ore per completed session over time. This is the only place the exponential curve
/// becomes visible to the player: the raw totals grow with both effort and power, but
/// per-session ore isolates power.
public struct GrowthLedger: Codable, Equatable, Sendable {
    public let weeks: [GrowthWeek]
    public let currentOrePerSession: Double
    /// Ratio against the oldest week that actually has sessions, nil when there is not
    /// enough history to make an honest comparison.
    public let multiplierSinceOldestWeek: Double?

    public init(
        weeks: [GrowthWeek],
        currentOrePerSession: Double,
        multiplierSinceOldestWeek: Double?
    ) {
        self.weeks = weeks
        self.currentOrePerSession = currentOrePerSession
        self.multiplierSinceOldestWeek = multiplierSinceOldestWeek
    }
}

public enum GrowthLedgerEngine {
    public static let trackedWeeks = 12

    public static func summarize(
        _ state: PlayerState,
        referenceDate: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> GrowthLedger {
        var local = calendar
        local.timeZone = timeZone
        var buckets: [Int: (sessions: Int, ore: Double)] = [:]
        for entry in state.history where entry.completed {
            guard let weeksAgo = local.dateComponents(
                [.weekOfYear],
                from: entry.endedAt,
                to: referenceDate
            ).weekOfYear, weeksAgo >= 0, weeksAgo < trackedWeeks else { continue }
            var bucket = buckets[weeksAgo] ?? (0, 0)
            bucket.sessions += 1
            bucket.ore += entry.oreEarned
            buckets[weeksAgo] = bucket
        }

        let weeks = (0..<trackedWeeks).reversed().map { weeksAgo in
            let bucket = buckets[weeksAgo] ?? (0, 0)
            return GrowthWeek(
                weeksAgo: weeksAgo,
                completedSessions: bucket.sessions,
                orePerSession: bucket.sessions > 0
                    ? bucket.ore / Double(bucket.sessions)
                    : 0
            )
        }

        let current = weeks.last(where: { $0.completedSessions > 0 })?.orePerSession ?? 0
        let oldest = weeks.first(where: { $0.completedSessions > 0 })
        var multiplier: Double?
        if let oldest, oldest.weeksAgo != weeks.last(where: { $0.completedSessions > 0 })?.weeksAgo,
           oldest.orePerSession > 0, current > 0 {
            let ratio = current / oldest.orePerSession
            multiplier = ratio.isFinite ? ratio : nil
        }
        return GrowthLedger(
            weeks: weeks,
            currentOrePerSession: current,
            multiplierSinceOldestWeek: multiplier
        )
    }
}
