import Foundation
import XCTest
@testable import DeepMine

final class GamePassiveSurfaceRefreshTests: XCTestCase {
    func testSuccessfulSnapshotWriteReloadsTheHomeWidget() throws {
        let fixture = try makeFixture()

        try fixture.writer.write(GameWidgetSnapshotFixtures.freshWaiting())

        XCTAssertEqual(fixture.receipts.timelineKinds, [GamePassiveSurfaceKinds.homeWidget])
    }

    func testRejectedOversizedWriteDoesNotIssueRefresh() throws {
        let fixture = try makeFixture()
        let oversized = GameSurfaceSnapshot(
            phase: .waiting,
            sessionID: String(repeating: "x", count: GameSurfaceSnapshotStore.maximumPayloadBytes),
            planID: "safe",
            regionID: "entry",
            depthMeters: 0,
            expectedOre: 0,
            earnedOre: 0,
            streakDays: 0,
            timerStartedAt: nil,
            timerEndsAt: nil,
            verificationGradeID: nil,
            veinID: nil,
            upgradeRecommendation: nil,
            todayFocusedMinutes: 0,
            todayGoalMinutes: 100,
            generatedAt: 0,
            staleAfter: 1
        )

        XCTAssertThrowsError(try fixture.writer.write(oversized))
        XCTAssertTrue(fixture.receipts.timelineKinds.isEmpty)
    }

    private func makeFixture() throws -> Fixture {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "DeepMineRefreshTests")
            .appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let receipts = RefreshReceipts()
        let refresher = GamePassiveSurfaceRefresher(
            reloadTimeline: { receipts.appendTimeline($0) }
        )
        return Fixture(
            writer: GameSurfaceSnapshotWriter(
                store: GameSurfaceSnapshotStore(directoryURL: directory),
                refresher: refresher
            ),
            receipts: receipts
        )
    }
}

private struct Fixture {
    let writer: GameSurfaceSnapshotWriter
    let receipts: RefreshReceipts
}

private final class RefreshReceipts: @unchecked Sendable {
    private let lock = NSLock()
    private var timelines: [String] = []

    var timelineKinds: [String] { lock.withLock { timelines } }

    func appendTimeline(_ kind: String) { lock.withLock { timelines.append(kind) } }
}

private extension GameWidgetSnapshotFixtures {
    static func freshWaiting() throws -> GameSurfaceSnapshot {
        guard case let .fresh(snapshot) = result(named: "waiting") else {
            throw FixtureSnapshotError.notFresh
        }
        return snapshot
    }
}

private enum FixtureSnapshotError: Error { case notFresh }
