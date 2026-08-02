import DeepMineCore
import Foundation
import SwiftData
import XCTest
@testable import DeepMine

@MainActor
final class GameStoreTests: XCTestCase {
    func testPreparingAndMiningPersistBeforeSystemsStart() async throws {
        let fixture = makeFixture()
        fixture.system.onStart = { XCTAssertEqual(fixture.repository.active?.phase, .mining) }
        try await fixture.store.start(length: .minutes15, plan: .safe)
        XCTAssertEqual(fixture.repository.savedPhases.prefix(2), [.preparing, .mining])
        XCTAssertEqual(fixture.store.activeSession?.phase, .mining)
        XCTAssertTrue(fixture.store.activeSession?.blockingEnabled == true)
        var interrupted = try XCTUnwrap(fixture.repository.active)
        interrupted.systemsConfigured = false
        fixture.repository.active = interrupted
        fixture.system.startCount = 0
        try await GameStore(repository: fixture.repository, coordinator: fixture.system, clock: fixture.clock).resume()
        XCTAssertEqual(fixture.system.startCount, 1)
        XCTAssertTrue(fixture.repository.active?.systemsConfigured == true)
    }
    func testPermissionDenialAndShieldFailureStayOpenWithVisibleReason() async throws {
        for reason in ["차단 권한이 거부되었습니다.", "차단 설정 저장에 실패했습니다."] {
            let fixture = makeFixture(shield: .open(reason: reason))
            try await fixture.store.start(length: .minutes15, plan: .safe)
            XCTAssertEqual(fixture.store.visibleReason, reason)
            fixture.clock.advance(seconds: 900)
            let report = try XCTUnwrap(try await fixture.store.completeIfNeeded())
            XCTAssertEqual(report.verificationGrade, .open)
        }
    }
    func testAlarmFallbackAndLiveActivityFailureRemainVisibleAndMining() async throws {
        let fixture = makeFixture(
            delivery: .localNotification, activityID: nil,
            warnings: ["실시간 진행 표시를 시작하지 못했지만 채굴은 계속됩니다."]
        )
        try await fixture.store.start(length: .minutes15, plan: .safe)
        XCTAssertEqual(fixture.store.activeSession?.alarmDelivery, .localNotification)
        XCTAssertNil(fixture.store.activeSession?.liveActivityID)
        XCTAssertEqual(fixture.store.activeSession?.phase, .mining)
        XCTAssertNotNil(fixture.store.visibleReason)
        let denied = makeFixture(delivery: .none, warnings: ["완료 알림을 예약하지 못했습니다."])
        try await denied.store.start(length: .minutes15, plan: .safe)
        XCTAssertEqual(denied.store.activeSession?.alarmDelivery, SessionAlarmDelivery.none)
        XCTAssertNotNil(denied.store.visibleReason)
    }
    func testForcedShieldRemovalCollapsesSession() async throws {
        let fixture = makeFixture()
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.system.onForce = { XCTAssertTrue(fixture.repository.active?.forcedRemovalPending == true) }
        fixture.system.forceSucceeds = false
        try await fixture.store.recordForcedShieldRemoval()
        XCTAssertTrue(fixture.repository.active?.forcedRemovalPending == true)
        XCTAssertTrue(fixture.store.visibleReason?.contains("다시 시도") == true)
        fixture.system.forceSucceeds = true
        try await fixture.store.resume()
        XCTAssertTrue(fixture.repository.active?.forcedRemovalPending == false)
        XCTAssertTrue(fixture.store.visibleReason?.contains("강제로 해제") == true)
        fixture.clock.advance(seconds: 900)
        let report = try XCTUnwrap(try await fixture.store.completeIfNeeded())
        XCTAssertEqual(report.verificationGrade, .collapsed)
        XCTAssertEqual(fixture.system.forceRemoveCount, 2)
    }
    func testTimeTamperDowngradesToOpen() async throws {
        let fixture = makeFixture()
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.clock.wall = fixture.clock.wall.addingTimeInterval(900)
        fixture.clock.monotonic += 30 * 1_000_000_000
        let report = try XCTUnwrap(try await fixture.store.completeIfNeeded())
        XCTAssertEqual(report.clockAssessment, .tampered)
        XCTAssertEqual(report.verificationGrade, .open)
    }
    func testRebootUsesWallTimeWithoutDowngrade() async throws {
        let fixture = makeFixture(monotonic: 10_000_000_000)
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.clock.wall = fixture.clock.wall.addingTimeInterval(900)
        fixture.clock.monotonic = 1
        let report = try XCTUnwrap(try await fixture.store.completeIfNeeded())
        XCTAssertEqual(report.clockAssessment, .rebooted)
        XCTAssertEqual(report.verificationGrade, .sealed)
        XCTAssertEqual(report.focusedMinutes, 15)
    }
    func testSafeAndSurveyAbandonmentEarnPartialLiveMineReward() async throws {
        for plan in [MinePlan.safe, .survey] {
            let fixture = makeFixture()
            fixture.repository.player = PlayerState(equipment: EquipmentLevels(cart: 2))
            try await fixture.store.start(length: .minutes15, plan: plan)
            fixture.clock.advance(seconds: 300)
            let report = try await fixture.store.abandon()
            XCTAssertEqual(report.outcome, .abandoned(elapsedMinutes: 5))
            XCTAssertGreaterThan(report.oreEarned, 0)
            XCTAssertGreaterThan(report.depthGainedMeters, 0)
        }
    }
    func testDeepAbandonmentEarnsZeroWithWorkingAutomation() async throws {
        let fixture = makeFixture()
        fixture.repository.player = PlayerState(equipment: EquipmentLevels(cart: 2))
        try await fixture.store.start(length: .minutes15, plan: .deep)
        fixture.clock.advance(seconds: 300)
        let report = try await fixture.store.abandon()
        XCTAssertEqual(report.oreEarned, 0)
        XCTAssertEqual(report.depthGainedMeters, 0)
    }
    func testPostPrestigeRunUsesCappedLifetimeGrowthInTheLiveMine() async throws {
        let fixture = makeFixture()
        let starting = PlayerState(
            equipment: EquipmentLevels(cart: 2), runFocusCredits: 0, lifetimeFocusCredits: 20
        )
        fixture.repository.player = starting
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.clock.advance(seconds: 900)
        let report = try XCTUnwrap(try await fixture.store.completeIfNeeded())
        let capped = try projectedOre(
            from: starting, growthFocusCredits: 20,
            vein: report.vein, completionID: report.completionID
        )
        let baseline = try projectedOre(
            from: starting, growthFocusCredits: 0,
            vein: report.vein, completionID: report.completionID
        )
        XCTAssertEqual(report.oreEarned, capped, accuracy: 0.000_001)
        XCTAssertGreaterThan(report.oreEarned, baseline)
    }
    func testCompletionAcrossMidnightCreditsCompletionDay() async throws {
        var calendar = Calendar(identifier: .gregorian)
        let zone = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        calendar.timeZone = zone
        let start = try XCTUnwrap(calendar.date(from: DateComponents(
            timeZone: zone, year: 2026, month: 7, day: 29, hour: 23, minute: 50
        )))
        let fixture = makeFixture(wall: start, calendar: calendar, timeZone: zone)
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.clock.advance(seconds: 900)
        _ = try await fixture.store.completeIfNeeded()
        let expected = DayKey(year: 2026, month: 7, day: 30)
        XCTAssertEqual(fixture.repository.player.dailyRecords.last?.dayKey, expected)
        XCTAssertEqual(fixture.repository.player.latestDayKey, expected)
    }
    func testRelaunchAfterEndAppliesRewardExactlyOnce() async throws {
        let fixture = makeFixture()
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.clock.advance(seconds: 900)
        fixture.repository.failCleanupNumber = 1
        let relaunched = GameStore(
            repository: fixture.repository, coordinator: fixture.system, clock: fixture.clock
        )
        do { try await relaunched.resume(); XCTFail("Expected cleanup checkpoint failure") }
        catch is FakeStoreError {}
        XCTAssertEqual(fixture.repository.active?.phase, .completed)
        try await GameStore(repository: fixture.repository, coordinator: fixture.system, clock: fixture.clock).resume()
        XCTAssertEqual(fixture.repository.commitCount, 1)
        XCTAssertEqual(fixture.repository.player.history.count, 1)
        XCTAssertNotNil(relaunched.returnReport)
        XCTAssertEqual(fixture.system.recoverCount, 3)
    }
    func testFailedPostSystemPersistenceRollsBackAndLeavesPreparing() async throws {
        let fixture = makeFixture(shield: .open(reason: "첫 설정 실패"))
        fixture.repository.failSaveNumber = 3
        do { try await fixture.store.start(length: .minutes15, plan: .safe); XCTFail("Expected persistence failure") }
        catch is FakeStoreError {}
        XCTAssertEqual(fixture.system.finishCount, 1)
        XCTAssertEqual(fixture.repository.active?.phase, .preparing)
        fixture.system.startResult = SessionSystemStartResult(
            shield: .sealed, alarmDelivery: .alarmKit, liveActivityID: "retry", warnings: []
        )
        try await fixture.store.resume()
        XCTAssertTrue(fixture.repository.active?.blockingEnabled == true)
        XCTAssertNil(fixture.repository.active?.openReason)
    }
    func testFailedAbandonCommitRecoversRequestedAbandonExactlyOnce() async throws {
        let fixture = makeFixture()
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.clock.advance(seconds: 300)
        fixture.repository.failCommitNumber = 1
        do { _ = try await fixture.store.abandon(); XCTFail("Expected commit failure") }
        catch is FakeStoreError {}
        XCTAssertTrue(fixture.repository.active?.abandonRequested == true)
        XCTAssertEqual(fixture.system.finishCount, 0)
        let attempted = try XCTUnwrap(fixture.repository.lastAttemptedReport)
        fixture.clock.advance(seconds: 600)
        try await GameStore(repository: fixture.repository, coordinator: fixture.system, clock: fixture.clock).resume()
        XCTAssertEqual(fixture.repository.commitCount, 1)
        XCTAssertEqual(fixture.repository.player.history.count, 1)
        XCTAssertEqual(fixture.repository.report?.outcome, attempted.outcome)
        XCTAssertEqual(fixture.repository.report?.oreEarned, attempted.oreEarned)
    }
    func testQueuedStartAndAbandonDrainThroughGameStore() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "GameStoreQueue-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try GameRepository.inMemory()
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        let initialStore = GameStore(repository: repository, coordinator: system, clock: clock)
        let queue = GameCommandQueue(directoryURL: directory)
        let start = GameCommand(action: .startSession(length: .minutes15, plan: .safe))
        try queue.enqueue(start)
        XCTAssertTrue(try initialStore.acceptQueuedCommand(start))
        let store = GameStore(repository: repository, coordinator: system, clock: clock)
        _ = try queue.drain(into: repository, sessionHandler: store.acceptQueuedCommand)
        try await store.resume()
        try queue.enqueue(GameCommand(action: .abandonSession))
        _ = try queue.drain(into: repository, sessionHandler: store.acceptQueuedCommand)
        try await store.resume()
        XCTAssertNil(store.activeSession)
        XCTAssertNotNil(store.returnReport)
        XCTAssertTrue(try queue.pendingCommands().isEmpty)
    }
    private func projectedOre(
        from player: PlayerState, growthFocusCredits: Double,
        vein: VeinKind?, completionID: UUID
    ) throws -> Double {
        let input = RewardInput(
            completionID: completionID, outcome: .completed,
            sessionLength: .minutes15, plan: .safe, verificationGrade: .sealed,
            growthFocusCredits: growthFocusCredits, streakDays: 0, dailySessionNumber: 1,
            equipment: player.equipment, vein: vein, resonanceBoostActive: false,
            permanentUpgrades: player.permanentUpgrades
        )
        let basis = try RewardCalculator.calculate(input)
        let rate = basis.breakdown.combinedMultiplier
            / max(1, basis.breakdown.equipment) / max(1, basis.breakdown.permanent)
        var projected = player
        return MiningLoop.advance(
            seconds: TimeInterval(basis.focusedMinutes * 60) * rate, in: &projected
        ).oreGained.doubleValue
    }
    private func makeFixture(
        shield: SessionShieldOutcome = .sealed,
        delivery: SessionAlarmDelivery = .alarmKit,
        activityID: String? = "activity", warnings: [String] = [],
        wall: Date = Date(timeIntervalSince1970: 1_800_000_000),
        monotonic: UInt64 = 1_000_000_000,
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!
    ) -> GameStoreFixture {
        let repository = FakeSessionRepository()
        let system = FakeSystemCoordinator()
        system.startResult = SessionSystemStartResult(
            shield: shield, alarmDelivery: delivery, liveActivityID: activityID, warnings: warnings
        )
        let clock = FakeClock(wall: wall, monotonic: monotonic)
        return GameStoreFixture(
            repository: repository, system: system, clock: clock,
            store: GameStore(
                repository: repository, coordinator: system, clock: clock,
                calendar: calendar, timeZone: timeZone
            )
        )
    }
}
