import DeepMineCore
import XCTest
@testable import DeepMineProbe

@MainActor
final class GameStoreSessionPresentationTests: XCTestCase {
    func testReturnTimelineMatchesTheThreeBeatContract() {
        XCTAssertEqual(ReturnReportTimeline.rewardRevealMilliseconds, 900)
        XCTAssertEqual(ReturnReportTimeline.nextRevealMilliseconds, 1_900)
    }

    func testReturnPresentationFailureProducesRecoverableState() {
        let repository = FakeSessionRepository()
        repository.failPlayerLoad = true
        let report = GameReturnReport(
            sessionID: UUID(), completionID: UUID(), outcome: .completed,
            verificationGrade: .sealed, focusedMinutes: 25, oreEarned: 110,
            vein: nil, depthMeters: 42,
            completedAt: Date(timeIntervalSince1970: 1_800_000_000),
            clockAssessment: .valid, warnings: []
        )
        let store = GameStore(
            repository: repository,
            coordinator: FakeSystemCoordinator(),
            clock: FakeClock()
        )

        XCTAssertEqual(store.returnPresentationState(for: report), .failed)
    }


    func testReturnPresentationKeepsUnaffordableRecommendationTruthful() throws {
        let repository = FakeSessionRepository()
        let completionID = UUID()
        repository.player = PlayerState(
            resources: Resources(ore: 0),
            equipment: EquipmentLevels(),
            lifetimeFocusCredits: 3,
            history: [SessionHistoryEntry(
                completionID: completionID,
                endedAt: Date(timeIntervalSince1970: 1_800_000_000),
                focusedMinutes: 25,
                focusCredits: 1,
                plan: .safe,
                verificationGrade: .sealed,
                oreEarned: 110,
                vein: nil,
                depthAfter: 42,
                completed: true
            )],
            onboardingStage: .complete
        )
        let report = GameReturnReport(
            sessionID: UUID(), completionID: completionID, outcome: .completed,
            verificationGrade: .sealed, focusedMinutes: 25, oreEarned: 110,
            vein: nil, depthMeters: 42,
            completedAt: Date(timeIntervalSince1970: 1_800_000_000),
            clockAssessment: .valid, warnings: []
        )
        repository.report = report
        let store = GameStore(
            repository: repository,
            coordinator: FakeSystemCoordinator(),
            clock: FakeClock()
        )

        let presentation = try store.returnPresentation(for: report)

        let recommendation = try XCTUnwrap(presentation.recommendation)
        XCTAssertFalse(recommendation.isAffordable)
        XCTAssertEqual(recommendation.availableOre, 0)
        XCTAssertGreaterThan(recommendation.cost, recommendation.availableOre)
        XCTAssertEqual(presentation.report.completionID, completionID)
    }

    func testFeedbackReceiptSurvivesRecreationAndHonorsPreferences() {
        let suite = "GameFeedbackTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: GameFeedback.soundPreferenceKey)
        var hapticCount = 0
        var soundCount = 0
        let completionID = UUID()
        let first = GameFeedback(
            defaults: defaults,
            scope: "test",
            haptic: { _ in hapticCount += 1 },
            sound: { soundCount += 1 }
        )

        XCTAssertTrue(first.playRewardOnce(completionID: completionID, grade: .sealed))
        let relaunched = GameFeedback(
            defaults: defaults,
            scope: "test",
            haptic: { _ in hapticCount += 1 },
            sound: { soundCount += 1 }
        )
        XCTAssertFalse(relaunched.playRewardOnce(completionID: completionID, grade: .sealed))
        XCTAssertEqual(hapticCount, 1)
        XCTAssertEqual(soundCount, 0)
    }

    func testProjectionUsesCoreVerificationAndAbandonmentRules() throws {
        let repository = FakeSessionRepository()
        repository.player = PlayerState(
            equipment: EquipmentLevels(drill: 2, cart: 2, lamp: 2),
            completedSessionCount: 3,
            onboardingStage: .complete
        )
        let store = GameStore(
            repository: repository,
            coordinator: FakeSystemCoordinator(),
            clock: FakeClock()
        )
        let sealed = try store.rewardProjection(
            length: .minutes25,
            plan: .safe,
            grade: .sealed
        )
        let open = try store.rewardProjection(
            length: .minutes25,
            plan: .safe,
            grade: .open
        )
        XCTAssertEqual(open.completedReward.ore, sealed.completedReward.ore * 0.75, accuracy: 0.000_001)
        XCTAssertGreaterThan(sealed.abandonmentReward.ore, 0)

        let survey = try store.rewardProjection(
            length: .minutes25,
            plan: .survey,
            grade: .sealed
        )
        XCTAssertGreaterThan(survey.abandonmentReward.ore, 0)
        let deep = try store.rewardProjection(
            length: .minutes25,
            plan: .deep,
            grade: .sealed
        )
        XCTAssertEqual(deep.abandonmentReward.ore, 0)
    }

    func testRefreshSnapshotReadsPersistedActiveSession() throws {
        let repository = FakeSessionRepository()
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        let store = GameStore(repository: repository, coordinator: system, clock: clock)
        try store.startForTest(length: .minutes15, plan: .safe)

        let relaunched = GameStore(repository: repository, coordinator: system, clock: clock)
        XCTAssertNotNil(try relaunched.refreshSnapshot().activeSession)
    }

    func testVisibleGradeMatchesRemovedShieldAndClockTamper() throws {
        let repository = FakeSessionRepository()
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        let store = GameStore(repository: repository, coordinator: system, clock: clock)
        try store.startForTest(length: .minutes15, plan: .safe)
        let session = try XCTUnwrap(repository.active)
        system.integrity = .removed
        XCTAssertEqual(store.currentVerificationGrade(for: session), .collapsed)

        system.integrity = .maintained
        clock.wall = clock.wall.addingTimeInterval(60)
        XCTAssertEqual(store.currentVerificationGrade(for: session), .open)
    }
}

private extension GameStore {
    func startForTest(length: SessionLength, plan: MinePlan) throws {
        let session = PersistedGameSession(
            id: UUID(), completionID: UUID(), originCommandID: nil,
            length: length, plan: plan,
            startedAt: clock.wallNow(),
            endsAt: clock.wallNow().addingTimeInterval(TimeInterval(length.minutes * 60)),
            clockAnchor: ClockIntegrityChecker.start(source: clock),
            randomSeed: 1, phase: .mining, systemsConfigured: true,
            abandonRequested: false, abandonSnapshot: nil,
            blockingEnabled: true, shieldMaintained: true,
            forcedShieldRemoval: false, forcedRemovalPending: false,
            openReason: nil, alarmDelivery: .none, liveActivityID: nil, warnings: []
        )
        try repository.saveActiveSession(session, commandID: nil)
    }
}
