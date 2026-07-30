import DeepMineCore
import Foundation
import UIKit
import XCTest
@testable import DeepMineProbe

@MainActor
final class GameActivityFoundationTests: XCTestCase {
    func testActivityContentStateRoundTripsBelowFourKilobytes() throws {
        let snapshot = GameActivitySurfaceFixture.snapshot(named: "surface-vein")
        let state = DeepMineActivityAttributes.ContentState(snapshot: snapshot)

        let data = try JSONEncoder().encode(state)

        XCTAssertLessThan(data.count, Balance.activityContentMaximumBytes)
        XCTAssertEqual(
            try JSONDecoder().decode(DeepMineActivityAttributes.ContentState.self, from: data),
            state
        )
        XCTAssertEqual(Balance.passiveSnapshotFreshnessSeconds, 15 * 60)
        XCTAssertEqual(Balance.completedActivityRetentionSeconds, 4 * 60 * 60)
    }

    func testCompletionDismissalNeverExceedsFourHours() {
        let now = GameActivitySurfaceFixture.referenceDate
        let snapshot = makeSnapshot(staleAfter: now.addingTimeInterval(8 * 60 * 60))

        let dismissal = LiveActivityLifecycle.completionDismissalDate(
            snapshot: snapshot,
            now: now
        )

        XCTAssertEqual(
            dismissal,
            now.addingTimeInterval(Balance.completedActivityRetentionSeconds)
        )
    }

    func testActualOpenProjectionIsLowerThanSealedProjection() throws {
        let clock = FakeClock()
        let player = PlayerState(
            resources: Resources(ore: 1_000),
            lifetimeFocusCredits: 3,
            streakDays: 7,
            onboardingStage: .complete
        )
        let session = makeSession(at: clock.wall)
        let calendar = Calendar(identifier: .iso8601)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        let sealed = try GameSurfaceSnapshotMapper.active(
            session: session, player: player, grade: .sealed,
            at: clock.wall, calendar: calendar, timeZone: timeZone
        )
        let open = try GameSurfaceSnapshotMapper.active(
            session: session, player: player, grade: .open,
            at: clock.wall, calendar: calendar, timeZone: timeZone
        )

        XCTAssertGreaterThan(sealed.expectedOre, open.expectedOre)
        XCTAssertEqual(
            open.expectedOre,
            sealed.expectedOre * Balance.openVerificationMultiplier,
            accuracy: 0.000_001
        )
        XCTAssertEqual(open.earnedOre, 0)
        XCTAssertNil(open.veinID)
    }

    func testCompletionPassesActualTerminalSnapshotToCoordinator() async throws {
        let fixture = makeStoreFixture()
        try await fixture.store.start(length: .minutes15, plan: .safe)
        fixture.clock.advance(seconds: 15 * 60)

        let completed = try await fixture.store.completeIfNeeded()
        let report = try XCTUnwrap(completed)
        let snapshot = try XCTUnwrap(fixture.system.completedSnapshots.last)

        XCTAssertEqual(snapshot.outcomeID, "completed")
        XCTAssertEqual(snapshot.earnedOre, report.oreEarned)
        XCTAssertEqual(snapshot.veinID, report.vein?.rawValue)
        XCTAssertEqual(snapshot.verificationGradeID, report.verificationGrade.rawValue)
        XCTAssertNotNil(snapshot.upgradeRecommendation)
        XCTAssertEqual(snapshot.phase, report.vein == nil ? .completed : .vein)
    }

    func testAbandonedAndCollapsedReturnsPublishDistinctActualStates() async throws {
        let abandoned = makeStoreFixture()
        try await abandoned.store.start(length: .minutes15, plan: .safe)
        abandoned.clock.advance(seconds: 5 * 60)
        _ = try await abandoned.store.abandon()
        XCTAssertEqual(abandoned.system.completedSnapshots.last?.outcomeID, "abandoned")
        XCTAssertEqual(abandoned.system.completedSnapshots.last?.phase, .completed)

        let collapsed = makeStoreFixture()
        try await collapsed.store.start(length: .minutes15, plan: .safe)
        collapsed.clock.advance(seconds: 5 * 60)
        try await collapsed.store.recordForcedShieldRemoval()
        _ = try await collapsed.store.abandon()
        XCTAssertEqual(collapsed.system.completedSnapshots.last?.outcomeID, "abandoned")
        XCTAssertEqual(collapsed.system.completedSnapshots.last?.phase, .collapsed)
        XCTAssertEqual(
            collapsed.system.completedSnapshots.last?.verificationGradeID,
            VerificationGrade.collapsed.rawValue
        )
    }

    func testStaleProjectionOnlyNeutralizesMining() {
        let mining = GameActivitySurfaceFixture.snapshot(named: "surface-mining")

        XCTAssertEqual(mining.activityPhase(isStale: false), .mining)
        XCTAssertEqual(mining.activityPhase(isStale: true), .waiting)
        for state in ["surface-completed", "surface-vein", "surface-collapsed"] {
            let terminal = GameActivitySurfaceFixture.snapshot(named: state)
            XCTAssertEqual(terminal.activityPhase(isStale: true), terminal.phase)
        }
    }

    func testCompactStatusUsesShortLocalizedCopy() {
        let completed = GameActivitySurfaceFixture.snapshot(named: "surface-completed")
        let vein = GameActivitySurfaceFixture.snapshot(named: "surface-vein")
        let collapsed = GameActivitySurfaceFixture.snapshot(named: "surface-collapsed")
        let stale = GameActivitySurfaceFixture.snapshot(named: "surface-stale")

        let locale = Locale.current
        XCTAssertEqual(
            GameSurfaceText.compactStatus(completed, isStale: false, locale: locale),
            GameSurfaceText.localized("surface.compact.completed", locale: locale)
        )
        XCTAssertEqual(
            GameSurfaceText.compactStatus(vein, isStale: false, locale: locale),
            GameSurfaceText.localized("surface.compact.vein", locale: locale)
        )
        XCTAssertEqual(
            GameSurfaceText.compactStatus(collapsed, isStale: false, locale: locale),
            GameSurfaceText.localized("surface.compact.collapsed", locale: locale)
        )
        XCTAssertEqual(
            GameSurfaceText.compactStatus(stale, isStale: true, locale: locale),
            GameSurfaceText.localized("surface.compact.waiting", locale: locale)
        )
    }

    func testUnknownVeinAndRecommendationAccessibilityFailTruthfully() throws {
        let unknown = GameActivitySurfaceFixture.snapshot(named: "surface-vein-unknown")
        XCTAssertNil(GameSurfaceText.vein(unknown.veinID, locale: Locale(identifier: "ko")))
        let locale = Locale.current
        XCTAssertEqual(
            GameSurfaceText.phase(unknown, locale: locale),
            GameSurfaceText.localized("surface.resultReady", locale: locale)
        )

        let recommendation = try XCTUnwrap(
            GameActivitySurfaceFixture.snapshot(named: "surface-completed")
                .upgradeRecommendation
        )
        let label = GameSurfaceText.recommendationAccessibilityLabel(
            recommendation,
            locale: locale
        )
        XCTAssertTrue(label.contains(
            GameSurfaceText.localized("surface.recommendationAction", locale: locale)
        ))
        XCTAssertTrue(label.contains("\(GameSurfaceText.localized("surface.level", locale: locale)) 3"))
        XCTAssertTrue(label.contains(
            "\(GameSurfaceText.localized("surface.cost", locale: locale)) 138"
        ))
    }

    func testStartIntentCarriesRequestedLengthAndCurrentPlan() {
        let intent = StartSessionIntent(length: .minutes50, planID: MinePlan.survey.rawValue)

        XCTAssertEqual(intent.lengthID, SessionLength.minutes50.rawValue)
        XCTAssertEqual(intent.planID, MinePlan.survey.rawValue)
    }

    func testTerminalPixelSpritesResolveAtTwentyFourPoints() throws {
        for name in ["CompletedSprite", "VeinSprite", "CollapsedSprite"] {
            let image = try XCTUnwrap(UIImage(named: name), name)
            XCTAssertEqual(image.size, CGSize(width: 24, height: 24), name)
        }
    }

    private func makeStoreFixture() -> GameStoreFixture {
        let repository = FakeSessionRepository()
        repository.player = PlayerState(
            resources: Resources(ore: 1_000),
            completedSessionCount: 3,
            onboardingStage: .complete
        )
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        return GameStoreFixture(
            repository: repository,
            system: system,
            clock: clock,
            store: GameStore(repository: repository, coordinator: system, clock: clock)
        )
    }

    private func makeSession(at date: Date) -> PersistedGameSession {
        PersistedGameSession(
            id: UUID(), completionID: UUID(), originCommandID: nil,
            length: .minutes25, plan: .survey,
            startedAt: date, endsAt: date.addingTimeInterval(25 * 60),
            clockAnchor: ClockAnchor(wallClock: date, monotonicNanoseconds: 1),
            randomSeed: 1, phase: .mining, systemsConfigured: true,
            abandonRequested: false, abandonSnapshot: nil,
            blockingEnabled: true, shieldMaintained: true,
            forcedShieldRemoval: false, forcedRemovalPending: false,
            openReason: nil, alarmDelivery: .alarmKit, liveActivityID: nil, warnings: []
        )
    }

    private func makeSnapshot(staleAfter: Date) -> GameSurfaceSnapshot {
        GameSurfaceSnapshot(
            phase: .completed, sessionID: "session", outcomeID: "completed",
            planID: "safe", regionID: "entry", depthMeters: 12,
            expectedOre: 0, earnedOre: 100, streakDays: 1,
            timerStartedAt: nil, timerEndsAt: nil, verificationGradeID: "sealed",
            veinID: nil, upgradeRecommendation: nil,
            todayFocusedMinutes: 25, todayGoalMinutes: 100,
            generatedAt: GameActivitySurfaceFixture.referenceDate.timeIntervalSince1970,
            staleAfter: staleAfter.timeIntervalSince1970
        )
    }
}
