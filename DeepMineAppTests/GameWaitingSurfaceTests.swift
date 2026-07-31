import DeepMineCore
import Foundation
import XCTest
@testable import DeepMine

@MainActor
final class GameWaitingSurfaceTests: XCTestCase {
    func testIdleResumePublishesFreshWaitingSurfaceThatCanStartSafeMine() async throws {
        let fixture = makeFixture()

        try await fixture.store.resume()

        let snapshot = try XCTUnwrap(fixture.system.waitingSnapshots.last)
        XCTAssertEqual(snapshot.phase, .waiting)
        XCTAssertNil(snapshot.sessionID)
        XCTAssertGreaterThan(snapshot.staleAfter, fixture.clock.wall.timeIntervalSince1970)
        XCTAssertEqual(
            GameSystemEntryPolicy.startAction(for: .fresh(snapshot)),
            .startSession(length: .minutes25, plan: .safe)
        )

        try await fixture.store.start(length: .minutes25, plan: .safe)
        XCTAssertEqual(fixture.store.activeSession?.phase, .mining)
    }

    func testResumePreservesUnconsumedTerminalSurface() async throws {
        let fixture = makeFixture()
        fixture.repository.report = makeReport()

        try await fixture.store.resume()

        XCTAssertEqual(fixture.store.returnReport, fixture.repository.report)
        XCTAssertTrue(fixture.system.waitingSnapshots.isEmpty)
    }

    func testDismissingReportConsumesItAndPublishesNextWaitingSurface() async throws {
        let fixture = makeFixture()
        fixture.repository.report = makeReport()
        fixture.store.returnReport = fixture.repository.report

        try await fixture.store.dismissReturnReport()

        XCTAssertNil(fixture.repository.report)
        XCTAssertNil(fixture.store.returnReport)
        let waiting = try XCTUnwrap(fixture.system.waitingSnapshots.last)
        XCTAssertEqual(waiting.phase, .waiting)
        XCTAssertEqual(
            GameSystemEntryPolicy.startAction(for: .fresh(waiting)),
            .startSession(length: .minutes25, plan: .safe)
        )
    }

    private func makeFixture() -> GameStoreFixture {
        let repository = FakeSessionRepository()
        repository.player = PlayerState(
            resources: Resources(ore: 250),
            onboardingStage: .complete,
            lastSelectedPlan: .survey,
            lastSelectedDuration: .minutes50
        )
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        var calendar = Calendar(identifier: .iso8601)
        let timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.timeZone = timeZone
        return GameStoreFixture(
            repository: repository,
            system: system,
            clock: clock,
            store: GameStore(
                repository: repository,
                coordinator: system,
                clock: clock,
                calendar: calendar,
                timeZone: timeZone
            )
        )
    }

    private func makeReport() -> GameReturnReport {
        GameReturnReport(
            sessionID: UUID(),
            completionID: UUID(),
            outcome: .completed,
            verificationGrade: .sealed,
            focusedMinutes: 25,
            oreEarned: 120,
            vein: nil,
            depthMeters: 90,
            completedAt: Date(timeIntervalSince1970: 1_800_000_000),
            clockAssessment: .valid,
            warnings: []
        )
    }
}
