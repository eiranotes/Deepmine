import DeepMineCore
import Foundation
import XCTest
@testable import DeepMineProbe

final class GameSurfaceSnapshotMapperTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let calendar = Calendar(identifier: .iso8601)
    private let timeZone = TimeZone(secondsFromGMT: 0)!

    func testWaitingSnapshotUsesPlayerSelectionRegionTodayAndRecommendation() throws {
        let player = try makePlayer()
        let recommendation = UpgradeRecommendation(
            equipment: .cart, currentLevel: 2, nextLevel: 3,
            cost: 249, marginalExpectedOre: 30, efficiency: 30 / 249
        )

        let snapshot = try GameSurfaceSnapshotMapper.waiting(
            player: player, recommendation: recommendation, at: now,
            calendar: calendar, timeZone: timeZone
        )

        XCTAssertEqual(snapshot.phase, .waiting)
        XCTAssertEqual(snapshot.planID, MinePlan.deep.rawValue)
        XCTAssertEqual(snapshot.regionID, MineRegion.crystal.rawValue)
        XCTAssertEqual(snapshot.depthMeters, player.depthMeters)
        XCTAssertEqual(snapshot.streakDays, 7)
        XCTAssertEqual(snapshot.todayFocusedMinutes, 40)
        XCTAssertEqual(snapshot.todayGoalMinutes, 100)
        XCTAssertEqual(snapshot.upgradeRecommendation?.equipmentID, EquipmentKind.cart.rawValue)
        XCTAssertNil(snapshot.sessionID)
    }

    func testPreparingAndMiningSnapshotsUseActualSessionAndRewardProjection() throws {
        let player = try makePlayer()
        let projection = try makeProjection(player: player)
        let preparing = makeSession(phase: .preparing)
        let mining = makeSession(phase: .mining)

        let waiting = try GameSurfaceSnapshotMapper.active(
            session: preparing, player: player, projection: projection,
            at: now, calendar: calendar, timeZone: timeZone
        )
        let active = try GameSurfaceSnapshotMapper.active(
            session: mining, player: player, projection: projection,
            at: now, calendar: calendar, timeZone: timeZone
        )

        XCTAssertEqual(waiting.phase, .waiting)
        XCTAssertEqual(active.phase, .mining)
        XCTAssertEqual(active.sessionID, mining.id.uuidString)
        XCTAssertEqual(active.planID, MinePlan.survey.rawValue)
        XCTAssertEqual(active.expectedOre, projection.completedReward.ore)
        XCTAssertEqual(active.verificationGradeID, VerificationGrade.sealed.rawValue)
        XCTAssertEqual(active.timerStartedAt, mining.startedAt.timeIntervalSince1970)
        XCTAssertEqual(active.timerEndsAt, mining.endsAt.timeIntervalSince1970)
        XCTAssertGreaterThanOrEqual(active.staleAfter, mining.endsAt.timeIntervalSince1970)
    }

    func testReturnMappingsCoverCompletedVeinAndCollapsedWithActualPresentation() throws {
        let player = try makePlayer()
        let completed = try returnedSnapshot(grade: .open, vein: nil, player: player)
        let vein = try returnedSnapshot(grade: .sealed, vein: .vault, player: player)
        let collapsed = try returnedSnapshot(grade: .collapsed, vein: .blue, player: player)

        XCTAssertEqual(completed.phase, .completed)
        XCTAssertEqual(completed.outcomeID, "completed")
        XCTAssertEqual(vein.phase, .vein)
        XCTAssertEqual(vein.veinID, VeinKind.vault.rawValue)
        XCTAssertEqual(collapsed.phase, .collapsed)
        XCTAssertEqual(collapsed.verificationGradeID, VerificationGrade.collapsed.rawValue)
        XCTAssertEqual(collapsed.earnedOre, 456)
        XCTAssertEqual(collapsed.regionID, MineRegion.ruins.rawValue)
        XCTAssertEqual(collapsed.upgradeRecommendation?.equipmentID, EquipmentKind.drill.rawValue)
    }

    private func returnedSnapshot(
        grade: VerificationGrade,
        vein: VeinKind?,
        player: PlayerState
    ) throws -> GameSurfaceSnapshot {
        let report = GameReturnReport(
            sessionID: UUID(), completionID: UUID(), outcome: .completed,
            verificationGrade: grade, focusedMinutes: 25, oreEarned: 456,
            vein: vein, depthMeters: 900, completedAt: now,
            clockAssessment: .valid, warnings: []
        )
        let presentation = ReturnReportPresentation(
            report: report, length: .minutes25, plan: .deep,
            recommendation: ReturnUpgradeRecommendation(
                equipment: .drill, currentLevel: 1, nextLevel: 2,
                cost: 100, availableOre: 500, marginalExpectedOre: 12
            ),
            nextPromise: ReturnNextPromise(
                currentRegion: .ruins, nextRegion: .abyss, remainingDepthMeters: 300
            )
        )
        return try GameSurfaceSnapshotMapper.returned(
            presentation: presentation, player: player, at: now,
            calendar: calendar, timeZone: timeZone
        )
    }

    private func makeProjection(player: PlayerState) throws -> SessionRewardProjection {
        let base = RewardInput(
            completionID: UUID(), outcome: .completed, sessionLength: .minutes25,
            plan: .survey, verificationGrade: .sealed,
            growthFocusCredits: player.lifetimeFocusCredits, streakDays: player.streakDays,
            dailySessionNumber: 2, equipment: player.equipment, vein: nil,
            resonanceBoostActive: false
        )
        let completed = try RewardCalculator.calculate(base)
        return SessionRewardProjection(
            length: .minutes25, plan: .survey, grade: .sealed,
            completedReward: completed, abandonmentReward: completed,
            veinChance: Balance.baseVeinChance * Balance.surveyVeinChanceMultiplier
        )
    }

    private func makeSession(phase: SessionPhase) -> PersistedGameSession {
        PersistedGameSession(
            id: UUID(), completionID: UUID(), originCommandID: nil,
            length: .minutes25, plan: .survey,
            startedAt: now, endsAt: now.addingTimeInterval(1_500),
            clockAnchor: ClockAnchor(wallClock: now, monotonicNanoseconds: 1),
            randomSeed: 1, phase: phase, systemsConfigured: phase != .preparing,
            abandonRequested: false, abandonSnapshot: nil,
            blockingEnabled: true, shieldMaintained: true,
            forcedShieldRemoval: false, forcedRemovalPending: false,
            openReason: nil, alarmDelivery: .alarmKit, liveActivityID: nil, warnings: []
        )
    }

    private func makePlayer() throws -> PlayerState {
        let day = try StreakEngine.dayKey(for: now, calendar: calendar, timeZone: timeZone)
        return PlayerState(
            resources: Resources(ore: 500), runFocusCredits: 12,
            lifetimeFocusCredits: 12, completedSessionCount: 8,
            dailyGoalMinutes: 100, streakDays: 7,
            dailyRecords: [DailyRecord(
                dayKey: day, focusedMinutes: 40, goalMinutes: 100,
                sessionCount: 1, goalEarned: false, streakApplied: false,
                wasRestDay: false, isFinalized: false
            )],
            lastSelectedPlan: .deep, lastSelectedDuration: .minutes50
        )
    }
}
