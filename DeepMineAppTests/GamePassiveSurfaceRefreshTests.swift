import DeepMineCore
import Foundation
import SwiftUI
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

@MainActor
final class GameRootMiningClockTests: XCTestCase {
    func testActiveSessionSkipsOfflineSettlement() async throws {
        let fixture = try await makeActiveRoot()
        let before = try fixture.repository.load()

        fixture.root.settleOfflineProduction()

        XCTAssertFalse(fixture.root.isHomeMiningClockLive)
        XCTAssertEqual(try fixture.repository.load(), before)
        XCTAssertNil(fixture.root.offlineSettlement)
    }

    func testActiveSessionPassesFalseToShaftLiveContract() async throws {
        let fixture = try await makeActiveRoot()
        let player = try fixture.repository.load()

        XCTAssertTrue(fixture.root.isSessionRecoveryComplete)
        XCTAssertFalse(fixture.root.clickerSectionView(player: .constant(player)).isLive)
    }

    func testHomeMiningClockPolicyRequiresResolvedSessionWithoutActiveFocus() {
        XCTAssertTrue(HomeMiningClockPolicy.isLive(
            isFixture: false,
            isSessionRecoveryComplete: true,
            isSessionStartInFlight: false,
            hasActiveSession: false
        ))
        XCTAssertFalse(HomeMiningClockPolicy.isLive(
            isFixture: false,
            isSessionRecoveryComplete: true,
            isSessionStartInFlight: false,
            hasActiveSession: true
        ))
        XCTAssertFalse(HomeMiningClockPolicy.isLive(
            isFixture: false,
            isSessionRecoveryComplete: false,
            isSessionStartInFlight: false,
            hasActiveSession: false
        ))
        XCTAssertFalse(HomeMiningClockPolicy.isLive(
            isFixture: false,
            isSessionRecoveryComplete: true,
            isSessionStartInFlight: true,
            hasActiveSession: false
        ))
    }

    private func makeActiveRoot() async throws -> ActiveRootFixture {
        let repository = try GameRepository.inMemory()
        try repository.save(PlayerState(
            onboardingStage: .complete,
            lastSettledAt: Date().addingTimeInterval(-3_600)
        ))
        let store = GameStore(
            repository: repository,
            coordinator: FakeSystemCoordinator()
        )
        try await store.start(length: .minutes15, plan: .safe)
        let root = GameRootView(
            repository: repository,
            gameStore: store,
            settingsCoordinator: DeterministicSettingsSystemCoordinator(),
            readinessProvider: FixedSessionReadinessProvider(.sealed),
            hasRecoveryNotice: false
        )
        return ActiveRootFixture(root: root, repository: repository)
    }
}

@MainActor
private struct ActiveRootFixture {
    let root: GameRootView
    let repository: GameRepository
}
