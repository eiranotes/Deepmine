import DeepMineCore
import Foundation
import XCTest
@testable import DeepMineProbe
@MainActor
final class GameCommandQueueTests: XCTestCase {
    func testOneHundredConcurrentAppendsRemainDecodable() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let commands = (0..<100).map { index in
            GameCommand(
                id: uuid(index),
                createdAt: Date(timeIntervalSince1970: Double(index)),
                action: .open(.overview)
            )
        }
        DispatchQueue.concurrentPerform(iterations: commands.count) { index in
            _ = try? fixture.queue.enqueue(commands[index])
        }
        let decoded = try fixture.queue.pendingCommands()
        XCTAssertEqual(decoded.count, 100)
        XCTAssertEqual(Set(decoded.map(\.id)), Set(commands.map(\.id)))
        XCTAssertEqual(try fixture.queue.receipts().count, 100)
    }
    func testSharedExtensionEnqueuerUsesTheAppQueueContract() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let command = GameCommand(action: .open(.overview))
        try GameCommandEnqueuer(directoryURL: fixture.directory).enqueue(command)
        XCTAssertEqual(try fixture.queue.pendingCommands(), [command])
        XCTAssertEqual(try fixture.queue.receipts().first?.state, .pending)
    }
    func testEquivalentPendingStartsCoalesceAndSameIDReplays() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let first = GameCommand(
            id: uuid(300), action: .startSession(length: .minutes25, plan: .safe)
        )
        let equivalent = GameCommand(
            id: uuid(301), action: .startSession(length: .minutes25, plan: .safe)
        )
        XCTAssertEqual(try fixture.queue.enqueue(first), .enqueued)
        XCTAssertEqual(try fixture.queue.enqueue(first), .replayed(.pending))
        XCTAssertEqual(
            try fixture.queue.enqueue(equivalent),
            .coalesced(existingCommandID: first.id)
        )
        XCTAssertEqual(try fixture.queue.pendingCommands(), [first])
        let states = Dictionary(uniqueKeysWithValues: try fixture.queue.receipts().map {
            ($0.commandID, $0.state)
        })
        XCTAssertEqual(states[first.id], .pending)
        XCTAssertEqual(states[equivalent.id], .applied)
        XCTAssertEqual(try fixture.queue.enqueue(equivalent), .replayed(.applied))
        XCTAssertEqual(try fixture.queue.pendingCommands(), [first])
    }
    func testConflictingStartIsConsumedAndCannotStartLater() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let repository = try makeFundedRepository(in: fixture.directory)
        let accepted = GameCommand(action: .startSession(length: .minutes25, plan: .safe))
        let conflicting = GameCommand(action: .startSession(length: .minutes50, plan: .deep))
        try fixture.queue.enqueue(accepted)
        try fixture.queue.enqueue(conflicting)
        var handled: [UUID] = []
        let first = try fixture.queue.drain(into: repository, sessionHandler: { command in
            handled.append(command.id)
            return command.id == accepted.id
        })
        XCTAssertEqual(first.applied, 1)
        XCTAssertEqual(first.conflicts, 1)
        XCTAssertEqual(handled, [accepted.id, conflicting.id])
        XCTAssertTrue(try fixture.queue.pendingCommands().isEmpty)
        XCTAssertTrue(try fixture.queue.receipts().allSatisfy { $0.state == .applied })
        XCTAssertEqual(try fixture.queue.enqueue(accepted), .replayed(.applied))
        XCTAssertTrue(try fixture.queue.pendingCommands().isEmpty)
        handled.removeAll()
        let replay = try fixture.queue.drain(into: repository, sessionHandler: { command in
            handled.append(command.id)
            return true
        })
        XCTAssertEqual(replay, GameCommandDrainReport())
        XCTAssertTrue(handled.isEmpty)
    }
    func testRepositoryDrainAppliesEquipmentUpgrade() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let repository = try makeFundedRepository(in: fixture.directory)
        let command = GameCommand(action: .upgradeEquipment(.drill))
        try fixture.queue.enqueue(command)
        let report = try fixture.queue.drain(into: repository)
        XCTAssertEqual(report.applied, 1)
        XCTAssertEqual(try repository.load().equipment.drill, 2)
        XCTAssertTrue(try fixture.queue.pendingCommands().isEmpty)
        XCTAssertEqual(try fixture.queue.receipts().first?.state, .applied)
    }
    func testCrashAfterRepositoryCommitReplaysAsNoOp() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let repository = try makeFundedRepository(in: fixture.directory)
        let command = GameCommand(action: .upgradeEquipment(.drill))
        try fixture.queue.enqueue(command)
        XCTAssertThrowsError(
            try fixture.queue.drain(
                into: repository,
                afterRepositoryCommit: { _ in throw SimulatedCrash() }
            )
        )
        XCTAssertEqual(try repository.load().equipment.drill, 2)
        XCTAssertEqual(try fixture.queue.pendingCommands(), [command])
        XCTAssertEqual(try fixture.queue.receipts().first?.state, .applying)
        let replay = try fixture.queue.drain(into: repository)
        XCTAssertEqual(replay.duplicates, 1)
        XCTAssertEqual(try repository.load().equipment.drill, 2)
        XCTAssertTrue(try fixture.queue.pendingCommands().isEmpty)
        XCTAssertEqual(try fixture.queue.receipts().first?.state, .applied)
    }
    func testMalformedMiddleLineIsQuarantinedAndLaterCommandApplies() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let repository = try makeFundedRepository(in: fixture.directory)
        let first = GameCommand(action: .upgradeEquipment(.drill))
        let second = GameCommand(action: .upgradeEquipment(.cart))
        try fixture.queue.enqueue(first)
        try appendMalformedLine(in: fixture.directory)
        try fixture.queue.enqueue(second)
        let report = try fixture.queue.drain(into: repository)
        XCTAssertEqual(report.applied, 2)
        XCTAssertEqual(report.quarantined, 1)
        XCTAssertEqual(try repository.load().equipment, EquipmentLevels(drill: 2, cart: 2, lamp: 1))
        XCTAssertTrue(try fixture.queue.pendingCommands().isEmpty)
        let records = try quarantineRecords(in: fixture.directory)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.reason, "invalid-json")
    }
    func testRetentionKeepsRecentCommandsWithinConfiguredCountAndBytes() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let queue = GameCommandQueue(directoryURL: directory, maximumBytes: 1_200, retainedCount: 10)
        let commands = (0..<30).map { index in
            GameCommand(id: uuid(index), action: .open(.equipment))
        }
        for command in commands { try queue.enqueue(command) }
        let retained = try queue.pendingCommands()
        let data = try Data(contentsOf: directory.appending(path: GameCommandQueue.queueFilename))
        XCTAssertLessThanOrEqual(retained.count, 10)
        XCTAssertLessThanOrEqual(data.count, 1_200)
        XCTAssertEqual(retained.last?.id, commands.last?.id)
        XCTAssertEqual(GameCommandQueue.maximumBytes, 256 * 1_024)
        XCTAssertEqual(GameCommandQueue.retainedCommandCount, 500)
    }
    func testUpdatedReceiptBecomesMostRecentBeforeRetention() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let queue = GameCommandQueue(directoryURL: directory, retainedCount: 2)
        let commands = (0..<4).map { GameCommand(id: uuid($0), action: .open(.overview)) }
        try queue.enqueue(commands[0])
        try queue.enqueue(commands[1])
        try queue.enqueue(commands[2])
        try queue.enqueue(commands[1])
        try queue.enqueue(commands[3])
        XCTAssertEqual(try queue.receipts().map(\.commandID), [commands[1].id, commands[3].id])
    }
    func testQuarantineWriteFailureLeavesMalformedSourcePending() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let queueURL = directory.appending(path: GameCommandQueue.queueFilename)
        try Data("{malformed}\n".utf8).write(to: queueURL)
        let queue = GameCommandQueue(directoryURL: directory) { url in
            if url.lastPathComponent == GameCommandQueue.quarantineFilename {
                throw SimulatedWriteFailure()
            }
        }
        let repository = try makeFundedRepository(in: directory)
        XCTAssertThrowsError(try queue.drain(into: repository))
        XCTAssertEqual(try Data(contentsOf: queueURL), Data("{malformed}\n".utf8))
    }
    func testCorruptReceiptMirrorIsPreservedAndRebuilt() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let repository = try makeFundedRepository(in: fixture.directory)
        let first = GameCommand(action: .upgradeEquipment(.drill))
        let second = GameCommand(action: .upgradeEquipment(.cart))
        try fixture.queue.enqueue(first)
        try Data("truncated".utf8).write(
            to: fixture.directory.appending(path: GameCommandQueue.receiptFilename)
        )
        try fixture.queue.enqueue(second)
        let report = try fixture.queue.drain(into: repository)
        XCTAssertEqual(report.applied, 2)
        XCTAssertEqual(Set(try fixture.queue.receipts().map(\.commandID)), [first.id, second.id])
        let corruptDirectory = fixture.directory.appending(
            path: GameCommandQueue.corruptReceiptDirectory
        )
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: corruptDirectory.path).count, 1)
    }
    func testDrainRestoresAppliedIDsAfterInterveningExtensionEnqueue() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let repository = try makeFundedRepository(in: fixture.directory)
        let applied = GameCommand(action: .upgradeEquipment(.drill))
        try fixture.queue.enqueue(applied)
        _ = try fixture.queue.drain(into: repository)
        try Data("corrupt".utf8).write(
            to: fixture.directory.appending(path: GameCommandQueue.receiptFilename)
        )
        let pending = GameCommand(action: .open(.overview))
        try GameCommandEnqueuer(directoryURL: fixture.directory).enqueue(pending)
        _ = try fixture.queue.drain(into: repository)
        let states = Dictionary(uniqueKeysWithValues: try fixture.queue.receipts().map {
            ($0.commandID, $0.state)
        })
        XCTAssertEqual(states[applied.id], .applied)
        XCTAssertEqual(states[pending.id], .pending)
    }
    func testReceiptBoundPreservesLivePendingBeforeAppliedHistory() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = try makeFundedRepository(in: directory)
        let roomyQueue = GameCommandQueue(directoryURL: directory, retainedCount: 10)
        for equipment in EquipmentKind.allCases {
            try roomyQueue.enqueue(GameCommand(action: .upgradeEquipment(equipment)))
        }
        _ = try roomyQueue.drain(into: repository)
        try Data("corrupt".utf8).write(
            to: directory.appending(path: GameCommandQueue.receiptFilename)
        )
        let boundedQueue = GameCommandQueue(directoryURL: directory, retainedCount: 2)
        let pending = GameCommand(action: .open(.overview))
        try GameCommandEnqueuer(directoryURL: directory, retainedCount: 2).enqueue(pending)
        _ = try boundedQueue.drain(into: repository)
        let receipts = try boundedQueue.receipts()
        XCTAssertEqual(receipts.count, 2)
        XCTAssertEqual(receipts.last?.commandID, pending.id)
        XCTAssertEqual(receipts.last?.state, .pending)
    }
    func testSessionAndOpenCommandsRemainPendingForTheirAppOwners() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let repository = try makeFundedRepository(in: fixture.directory)
        let commands = [
            GameCommand(action: .startSession(length: .minutes25, plan: .safe)),
            GameCommand(action: .abandonSession),
            GameCommand(action: .open(.session))
        ]
        for command in commands { try fixture.queue.enqueue(command) }
        let report = try fixture.queue.drain(into: repository)
        XCTAssertEqual(report.deferred, 3)
        XCTAssertEqual(try fixture.queue.pendingCommands(), commands)
    }
    private func makeFundedRepository(in directory: URL) throws -> GameRepository {
        let repository = try GameRepository.open(
            storeURL: directory.appending(path: GameRepository.storeFilename)
        )
        try repository.save(PlayerState(resources: Resources(ore: 100_000)))
        return repository
    }
    private func appendMalformedLine(in directory: URL) throws {
        let url = directory.appending(path: GameCommandQueue.queueFilename)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("{malformed}\n".utf8))
        try handle.synchronize()
    }
    private func quarantineRecords(in directory: URL) throws -> [QuarantinedGameCommand] {
        let url = directory.appending(path: GameCommandQueue.quarantineFilename)
        let decoder = JSONDecoder()
        return try Data(contentsOf: url)
            .split(separator: 0x0A)
            .map { try decoder.decode(QuarantinedGameCommand.self, from: Data($0)) }
    }
    private func makeFixture() throws -> Fixture {
        let directory = try temporaryDirectory()
        return Fixture(directory: directory, queue: GameCommandQueue(directoryURL: directory))
    }
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "GameCommandQueueTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private func uuid(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!
    }
}
private struct Fixture {
    let directory: URL
    let queue: GameCommandQueue
    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}
private struct SimulatedCrash: Error {}
private struct SimulatedWriteFailure: Error {}
