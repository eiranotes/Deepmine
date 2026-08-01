import Foundation

public struct PlanSessionCount: Codable, Equatable, Sendable {
    public let plan: MinePlan
    public let count: Int

    public init(plan: MinePlan, count: Int) {
        self.plan = plan
        self.count = count
    }
}

/// A summary of everything the mine has recorded.
///
/// Replaces the focus-era `WeeklyLedger`, which bucketed by ISO week because the product
/// measured a weekly focus habit. An idle game is played in irregular bursts across
/// months, so a seven-day window mostly reports noise. The retained window is the whole
/// history, capped by `sessionHistoryLimit`.
public struct MineLedger: Codable, Equatable, Sendable {
    public let recordedRuns: Int
    public let completedRuns: Int
    public let deepestReturnMeters: Int
    public let oreEarned: Double
    public let planMix: [PlanSessionCount]
    public let entries: [SessionHistoryEntry]
    public let veinHistory: [SessionHistoryEntry]
    /// True when the history cap is hit, so the UI can say "at least" instead of
    /// implying a lifetime total it cannot see.
    public let isTruncated: Bool

    public init(
        recordedRuns: Int,
        completedRuns: Int,
        deepestReturnMeters: Int,
        oreEarned: Double,
        planMix: [PlanSessionCount],
        entries: [SessionHistoryEntry],
        veinHistory: [SessionHistoryEntry],
        isTruncated: Bool
    ) {
        self.recordedRuns = recordedRuns
        self.completedRuns = completedRuns
        self.deepestReturnMeters = deepestReturnMeters
        self.oreEarned = oreEarned
        self.planMix = planMix
        self.entries = entries
        self.veinHistory = veinHistory
        self.isTruncated = isTruncated
    }
}

public enum MineLedgerEngine {
    public static func summarize(_ state: PlayerState) -> MineLedger {
        let entries = state.history.sorted { $0.endedAt > $1.endedAt }
        let planMix = MinePlan.allCases.map { plan in
            PlanSessionCount(plan: plan, count: entries.count { $0.plan == plan })
        }
        return MineLedger(
            recordedRuns: entries.count,
            completedRuns: entries.count(where: \.completed),
            // The record, not the current position: prestige sends the player back to the
            // surface and a statistics page must not forget where they have been (D-046).
            deepestReturnMeters: max(
                state.recordDepthMeters,
                entries.map(\.depthAfter).max() ?? 0
            ),
            oreEarned: entries.reduce(0) { $0 + $1.oreEarned },
            planMix: planMix,
            entries: entries,
            veinHistory: entries.filter { $0.vein != nil },
            isTruncated: entries.count >= Balance.sessionHistoryLimit
        )
    }
}
