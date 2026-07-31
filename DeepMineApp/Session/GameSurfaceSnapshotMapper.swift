import DeepMineCore
import Foundation
enum GameSurfaceSnapshotMapper {
    static let defaultFreshnessWindow = Balance.passiveSnapshotFreshnessSeconds
    static let terminalFreshnessWindow = Balance.completedActivityRetentionSeconds

    static func waiting(
        player: PlayerState,
        recommendation: UpgradeRecommendation?,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone,
        freshnessWindow: TimeInterval = defaultFreshnessWindow
    ) throws -> GameSurfaceSnapshot {
        let today = try todayProgress(
            player: player,
            at: date,
            calendar: calendar,
            timeZone: timeZone
        )
        return GameSurfaceSnapshot(
            phase: .waiting,
            sessionID: nil,
            outcomeID: nil,
            planID: player.lastSelectedPlan.rawValue,
            regionID: WorldProgression.region(forDepth: player.depthMeters).rawValue,
            depthMeters: max(0, player.depthMeters),
            expectedOre: 0,
            earnedOre: 0,
            streakDays: max(0, player.streakDays),
            timerStartedAt: nil,
            timerEndsAt: nil,
            verificationGradeID: nil,
            veinID: nil,
            upgradeRecommendation: recommendation.map(mapRecommendation),
            todayFocusedMinutes: today.focused,
            todayGoalMinutes: today.goal,
            generatedAt: date.timeIntervalSince1970,
            staleAfter: date.addingTimeInterval(max(0, freshnessWindow)).timeIntervalSince1970
        )
    }

    static func active(
        session: PersistedGameSession,
        player: PlayerState,
        projection: SessionRewardProjection,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone,
        freshnessWindow: TimeInterval = defaultFreshnessWindow
    ) throws -> GameSurfaceSnapshot {
        try active(
            session: session,
            player: player,
            expectedOre: projection.completedReward.ore,
            grade: projection.grade,
            at: date,
            calendar: calendar,
            timeZone: timeZone,
            freshnessWindow: freshnessWindow
        )
    }

    static func active(
        session: PersistedGameSession,
        player: PlayerState,
        grade: VerificationGrade,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone,
        freshnessWindow: TimeInterval = defaultFreshnessWindow
    ) throws -> GameSurfaceSnapshot {
        let input = try rewardInput(
            session: session,
            player: player,
            grade: grade,
            at: date,
            calendar: calendar,
            timeZone: timeZone
        )
        return try active(
            session: session,
            player: player,
            expectedOre: RewardCalculator.calculate(input).ore,
            grade: grade,
            at: date,
            calendar: calendar,
            timeZone: timeZone,
            freshnessWindow: freshnessWindow
        )
    }

    private static func active(
        session: PersistedGameSession,
        player: PlayerState,
        expectedOre: Double,
        grade: VerificationGrade,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone,
        freshnessWindow: TimeInterval
    ) throws -> GameSurfaceSnapshot {
        let today = try todayProgress(
            player: player,
            at: date,
            calendar: calendar,
            timeZone: timeZone
        )
        let phase: GameSurfacePhase = switch session.phase {
        case .preparing: .waiting
        case .mining: .mining
        case .completed: .completed
        case .abandoned: grade == .collapsed ? .collapsed : .completed
        }
        let minimumFreshness = date.addingTimeInterval(max(0, freshnessWindow))
        return GameSurfaceSnapshot(
            phase: phase,
            sessionID: session.id.uuidString,
            outcomeID: nil,
            planID: session.plan.rawValue,
            regionID: WorldProgression.region(forDepth: player.depthMeters).rawValue,
            depthMeters: max(0, player.depthMeters),
            expectedOre: finiteNonnegative(expectedOre),
            earnedOre: 0,
            streakDays: max(0, player.streakDays),
            timerStartedAt: session.startedAt.timeIntervalSince1970,
            timerEndsAt: session.endsAt.timeIntervalSince1970,
            verificationGradeID: grade.rawValue,
            veinID: nil,
            upgradeRecommendation: nil,
            todayFocusedMinutes: today.focused,
            todayGoalMinutes: today.goal,
            generatedAt: date.timeIntervalSince1970,
            staleAfter: max(
                minimumFreshness.timeIntervalSince1970,
                session.endsAt.timeIntervalSince1970
            )
        )
    }

    static func returned(
        presentation: ReturnReportPresentation,
        player: PlayerState,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone,
        freshnessWindow: TimeInterval = terminalFreshnessWindow
    ) throws -> GameSurfaceSnapshot {
        let report = presentation.report
        let today = try todayProgress(
            player: player,
            at: date,
            calendar: calendar,
            timeZone: timeZone
        )
        let phase: GameSurfacePhase
        if report.verificationGrade == .collapsed {
            phase = .collapsed
        } else if report.vein != nil {
            phase = .vein
        } else {
            phase = .completed
        }
        return GameSurfaceSnapshot(
            phase: phase,
            sessionID: report.sessionID.uuidString,
            outcomeID: outcomeID(report.outcome),
            planID: presentation.plan.rawValue,
            regionID: WorldProgression.region(forDepth: report.depthMeters).rawValue,
            depthMeters: max(0, report.depthMeters),
            expectedOre: 0,
            earnedOre: finiteNonnegative(report.oreEarned),
            streakDays: max(0, player.streakDays),
            timerStartedAt: nil,
            timerEndsAt: nil,
            verificationGradeID: report.verificationGrade.rawValue,
            veinID: report.vein?.rawValue,
            upgradeRecommendation: presentation.recommendation.map(mapRecommendation),
            todayFocusedMinutes: today.focused,
            todayGoalMinutes: today.goal,
            generatedAt: date.timeIntervalSince1970,
            staleAfter: date.addingTimeInterval(max(0, freshnessWindow)).timeIntervalSince1970
        )
    }

    private static func todayProgress(
        player: PlayerState,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> (focused: Int, goal: Int) {
        let key = try MiningStreak.dayKey(
            for: date,
            calendar: calendar,
            timeZone: timeZone
        )
        let focused = player.dailyRecords.first { $0.dayKey == key }?.focusedMinutes ?? 0
        return (max(0, focused), max(0, player.dailyGoalMinutes))
    }

    private static func rewardInput(
        session: PersistedGameSession,
        player: PlayerState,
        grade: VerificationGrade,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) throws -> RewardInput {
        let key = try MiningStreak.dayKey(
            for: date,
            calendar: calendar,
            timeZone: timeZone
        )
        let daily = player.dailyRecords.first { $0.dayKey == key }
        return RewardInput(
            completionID: session.completionID,
            outcome: .completed,
            sessionLength: session.length,
            plan: session.plan,
            verificationGrade: grade,
            growthFocusCredits: player.lifetimeFocusCredits,
            streakDays: player.streakDays,
            dailySessionNumber: (daily?.sessionCount ?? 0) + 1,
            equipment: player.equipment,
            vein: nil,
            resonanceBoostActive: player.resonanceBoostPending,
            permanentUpgrades: player.permanentUpgrades
        )
    }

    private static func mapRecommendation(
        _ value: UpgradeRecommendation
    ) -> GameSurfaceUpgradeRecommendation {
        GameSurfaceUpgradeRecommendation(
            equipmentID: value.equipment.rawValue,
            currentLevel: value.currentLevel,
            nextLevel: value.nextLevel,
            cost: finiteNonnegative(value.cost),
            marginalExpectedOre: finiteNonnegative(value.marginalExpectedOre)
        )
    }

    private static func mapRecommendation(
        _ value: ReturnUpgradeRecommendation
    ) -> GameSurfaceUpgradeRecommendation {
        GameSurfaceUpgradeRecommendation(
            equipmentID: value.equipment.rawValue,
            currentLevel: value.currentLevel,
            nextLevel: value.nextLevel,
            cost: finiteNonnegative(value.cost),
            marginalExpectedOre: finiteNonnegative(value.marginalExpectedOre)
        )
    }

    private static func finiteNonnegative(_ value: Double) -> Double {
        value.isFinite ? max(0, value) : 0
    }

    private static func outcomeID(_ outcome: SessionOutcome) -> String {
        switch outcome {
        case .completed: "completed"
        case .abandoned: "abandoned"
        }
    }
}
