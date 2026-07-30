import DeepMineCore
import Foundation

enum GameWidgetSnapshotFixtures {
    static func result(named name: String, at date: Date = Date()) -> GameSurfaceSnapshotReadResult {
        switch name {
        case "missing": return .missing
        case "stale": return .stale(snapshot(phase: .mining, at: date, stale: true))
        case "mining": return .fresh(snapshot(phase: .mining, at: date))
        case "completed": return .fresh(snapshot(phase: .completed, at: date))
        case "vein": return .fresh(snapshot(phase: .vein, at: date))
        case "collapsed": return .fresh(snapshot(phase: .collapsed, at: date))
        default: return .fresh(snapshot(phase: .waiting, at: date))
        }
    }

    private static func snapshot(
        phase: GameSurfacePhase,
        at date: Date,
        stale: Bool = false
    ) -> GameSurfaceSnapshot {
        let terminal = phase == .completed || phase == .vein || phase == .collapsed
        return GameSurfaceSnapshot(
            phase: phase,
            sessionID: phase == .waiting ? nil : "widget-fixture-session",
            outcomeID: terminal ? (phase == .collapsed ? "abandoned" : "completed") : nil,
            planID: "safe",
            regionID: "crystal",
            depthMeters: 862,
            expectedOre: phase == .mining ? 12_345 : 0,
            earnedOre: terminal ? (phase == .collapsed ? 24 : 12_345) : 0,
            streakDays: 7,
            timerStartedAt: phase == .mining
                ? date.addingTimeInterval(-300).timeIntervalSince1970 : nil,
            timerEndsAt: phase == .mining
                ? date.addingTimeInterval(1_200).timeIntervalSince1970 : nil,
            verificationGradeID: phase == .collapsed ? "collapsed" : "sealed",
            veinID: phase == .vein ? "crystal" : nil,
            upgradeRecommendation: nil,
            todayFocusedMinutes: 75,
            todayGoalMinutes: 100,
            generatedAt: date.timeIntervalSince1970,
            staleAfter: stale
                ? date.addingTimeInterval(-1).timeIntervalSince1970
                : date.addingTimeInterval(Balance.passiveSnapshotFreshnessSeconds).timeIntervalSince1970
        )
    }
}
