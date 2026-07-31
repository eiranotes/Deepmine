import DeepMineCore
import Foundation
@testable import DeepMine

struct GameStoreFixture {
    let repository: FakeSessionRepository
    let system: FakeSystemCoordinator
    let clock: FakeClock
    let store: GameStore
}

enum FakeStoreError: Error { case write }

@MainActor
final class FakeSessionRepository: GameSessionRepository {
    var player = PlayerState()
    var active: PersistedGameSession?
    var report: GameReturnReport?
    var failPlayerLoad = false
    var savedPhases: [SessionPhase] = []
    var saveCount = 0
    var failSaveNumber: Int?
    var failCommitNumber: Int?
    var commitAttempts = 0
    var failCleanupNumber: Int?
    var cleanupAttempts = 0
    var commitCount = 0
    var lastAttemptedReport: GameReturnReport?
    var failPlayerSave = false
    var playerSaveAttempts = 0

    func loadPlayer() throws -> PlayerState {
        if failPlayerLoad { throw FakeStoreError.write }
        return player
    }
    func savePlayer(_ player: PlayerState) throws {
        playerSaveAttempts += 1
        if failPlayerSave { throw FakeStoreError.write }
        self.player = player
    }
    func loadActiveSession() throws -> PersistedGameSession? { active }
    func loadReturnReport() throws -> GameReturnReport? { report }
    func clearReturnReport() throws { report = nil }
    func saveActiveSession(_ session: PersistedGameSession, commandID: UUID?) throws {
        saveCount += 1
        if saveCount == failSaveNumber { throw FakeStoreError.write }
        active = session
        savedPhases.append(session.phase)
    }
    func markCommandApplied(_ commandID: UUID) throws {}
    func commitSession(
        player: PlayerState,
        report: GameReturnReport,
        cleanupSession: PersistedGameSession
    ) throws {
        commitAttempts += 1
        lastAttemptedReport = report
        if commitAttempts == failCommitNumber { throw FakeStoreError.write }
        self.player = player
        self.report = report
        active = cleanupSession
        commitCount += 1
    }
    func finishSessionCleanup(report: GameReturnReport) throws {
        cleanupAttempts += 1
        if cleanupAttempts == failCleanupNumber { throw FakeStoreError.write }
        self.report = report
        active = nil
    }
}

@MainActor
final class FakeSystemCoordinator: SessionSystemCoordinating {
    var startResult = SessionSystemStartResult(
        shield: .sealed, alarmDelivery: .alarmKit,
        liveActivityID: "activity", warnings: []
    )
    var integrity = SessionShieldIntegrity.maintained
    var onStart: (() -> Void)?
    var finishCount = 0
    var completedSnapshots: [GameSurfaceSnapshot] = []
    var forceRemoveCount = 0
    var recoverCount = 0
    var startCount = 0
    var waitingSnapshots: [GameSurfaceSnapshot] = []
    var waitingPublishSucceeds = true
    var onForce: (() -> Void)?
    var forceSucceeds = true
    func start(
        _ session: PersistedGameSession,
        player: PlayerState,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) async -> SessionSystemStartResult {
        startCount += 1
        onStart?()
        return startResult
    }
    func finish(
        _ session: PersistedGameSession,
        completedSnapshot: GameSurfaceSnapshot?
    ) async -> [String] {
        finishCount += 1
        if let completedSnapshot { completedSnapshots.append(completedSnapshot) }
        return []
    }
    func publishWaiting(_ snapshot: GameSurfaceSnapshot) async -> Bool {
        waitingSnapshots.append(snapshot)
        return waitingPublishSucceeds
    }
    func recoverExpiredShield(at date: Date) async -> [String] {
        recoverCount += 1
        return []
    }
    func shieldIntegrity(for session: PersistedGameSession) -> SessionShieldIntegrity { integrity }
    func forceRemoveShield(for session: PersistedGameSession) async -> Bool {
        forceRemoveCount += 1
        onForce?()
        return forceSucceeds
    }
}

final class FakeClock: DeepMineCore.ClockSource, @unchecked Sendable {
    var wall: Date
    var monotonic: UInt64
    init(
        wall: Date = Date(timeIntervalSince1970: 1_800_000_000),
        monotonic: UInt64 = 1_000_000_000
    ) {
        self.wall = wall
        self.monotonic = monotonic
    }
    func wallNow() -> Date { wall }
    func continuousNanoseconds() -> UInt64 { monotonic }
    func advance(seconds: TimeInterval) {
        wall = wall.addingTimeInterval(seconds)
        monotonic += UInt64(seconds * 1_000_000_000)
    }
}
