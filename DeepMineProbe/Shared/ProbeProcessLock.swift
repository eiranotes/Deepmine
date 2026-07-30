import Darwin
import DeepMineCore
import Foundation

@_silgen_name("flock")
private func processFlock(_ descriptor: Int32, _ operation: Int32) -> Int32

// The lock has a single lexical owner. Sendability allows acquisition off the
// cooperative executor while the descriptor remains locked across async work.
final class ProbeProcessLock: @unchecked Sendable {
    private var descriptor: Int32

    private init(descriptor: Int32) {
        self.descriptor = descriptor
    }

    static func acquire(
        filename: String,
        directoryURL: URL? = nil
    ) throws -> ProbeProcessLock {
        let directory = try directoryURL ?? ProbeSharedStores.directoryURL()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let url = directory.appending(path: filename)
        let descriptor = Darwin.open(url.path, O_CREAT | O_RDWR | O_CLOEXEC, mode_t(0o600))
        guard descriptor >= 0 else { throw currentPOSIXError() }
        guard processFlock(descriptor, LOCK_EX) == 0 else {
            let error = currentPOSIXError()
            Darwin.close(descriptor)
            throw error
        }
        return ProbeProcessLock(descriptor: descriptor)
    }

    func release() {
        guard descriptor >= 0 else { return }
        _ = processFlock(descriptor, LOCK_UN)
        Darwin.close(descriptor)
        descriptor = -1
    }

    deinit {
        release()
    }

    private static func currentPOSIXError() -> POSIXError {
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
}

enum GameCommandReceiptState: String, Codable, Sendable {
    case pending
    case applying
    case applied
}

struct GameCommandReceipt: Codable, Equatable, Sendable {
    let commandID: UUID
    var state: GameCommandReceiptState
    var updatedAt: Date
}

enum GameCommandEnqueueResult: Equatable, Sendable {
    case enqueued
    case replayed(GameCommandReceiptState)
    case coalesced(existingCommandID: UUID)
}

struct GameCommandEnqueuer: Sendable {
    static let queueFilename = "GameCommands.jsonl"
    static let lockFilename = "GameCommands.lock"
    static let receiptFilename = "AppliedCommands.json"
    static let corruptReceiptDirectory = "CorruptCommandReceipts"
    static let maximumBytes = 256 * 1_024
    static let retainedCount = 500

    let directoryURL: URL
    let maximumBytes: Int
    let retainedCount: Int

    init(
        directoryURL: URL,
        maximumBytes: Int = Self.maximumBytes,
        retainedCount: Int = Self.retainedCount
    ) {
        self.directoryURL = directoryURL
        self.maximumBytes = maximumBytes
        self.retainedCount = retainedCount
    }

    static func shared(fileManager: FileManager = .default) throws -> GameCommandEnqueuer {
        guard let directory = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: ProbeConstants.appGroupIdentifier
        ) else {
            throw ProbeStoreError.missingAppGroup(ProbeConstants.appGroupIdentifier)
        }
        return GameCommandEnqueuer(directoryURL: directory)
    }

    @discardableResult
    func enqueue(
        _ command: GameCommand,
        now: Date = Date()
    ) throws -> GameCommandEnqueueResult {
        let lock = try ProbeProcessLock.acquire(
            filename: Self.lockFilename,
            directoryURL: directoryURL
        )
        defer { lock.release() }
        let url = directoryURL.appending(path: Self.queueFilename)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let existing = FileManager.default.fileExists(atPath: url.path)
            ? try Data(contentsOf: url) : Data()
        var lines = existing.split(separator: 0x0A).map { Data($0) }
        let receiptURL = directoryURL.appending(path: Self.receiptFilename)
        var receipts = try readReceipts(at: receiptURL)
        let decoded = lines.compactMap { try? JSONDecoder().decode(GameCommand.self, from: $0) }
        if let receipt = receipts.first(where: { $0.commandID == command.id }),
           receipt.state == .applied {
            upsertReceipt(command.id, state: .applied, at: now, in: &receipts)
            try writeReceipts(receipts, to: receiptURL)
            return .replayed(.applied)
        }
        if decoded.contains(where: { $0.id == command.id }) {
            let state = receipts.first(where: { $0.commandID == command.id })?.state ?? .pending
            upsertReceipt(command.id, state: state, at: now, in: &receipts)
            try writeReceipts(receipts, to: receiptURL)
            return .replayed(state)
        }
        if command.action.isStartCommand,
           let pending = decoded.first(where: { candidate in
               candidate.action == command.action
                   && receipts.first(where: { $0.commandID == candidate.id })?.state != .applied
           }) {
            upsertReceipt(command.id, state: .applied, at: now, in: &receipts)
            try writeReceipts(receipts, to: receiptURL)
            return .coalesced(existingCommandID: pending.id)
        }
        lines.append(try JSONEncoder().encode(command))
        try writeLines(bounded(lines), to: url)
        upsertReceipt(command.id, state: .pending, at: now, in: &receipts)
        try writeReceipts(receipts, to: receiptURL)
        return .enqueued
    }

    private func readReceipts(at url: URL) throws -> [GameCommandReceipt] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            return try JSONDecoder().decode([GameCommandReceipt].self, from: Data(contentsOf: url))
        } catch {
            let corrupt = directoryURL.appending(path: Self.corruptReceiptDirectory)
            try FileManager.default.createDirectory(at: corrupt, withIntermediateDirectories: true)
            try FileManager.default.moveItem(
                at: url,
                to: corrupt.appending(path: "AppliedCommands-\(UUID().uuidString).json")
            )
            return []
        }
    }

    private func writeReceipts(_ values: [GameCommandReceipt], to url: URL) throws {
        let live = Array(values.filter { $0.state != .applied }.suffix(retainedCount))
        let terminal = Array(values.filter { $0.state == .applied }
            .suffix(max(0, retainedCount - live.count)))
        try writeSynced(JSONEncoder().encode(terminal + live), to: url)
    }

    private func upsertReceipt(
        _ id: UUID,
        state: GameCommandReceiptState,
        at date: Date,
        in receipts: inout [GameCommandReceipt]
    ) {
        receipts.removeAll { $0.commandID == id }
        receipts.append(GameCommandReceipt(commandID: id, state: state, updatedAt: date))
    }

    private func bounded(_ values: [Data]) -> [Data] {
        var lines = Array(values.suffix(retainedCount))
        var size = lines.reduce(0) { $0 + $1.count + 1 }
        while size > maximumBytes, !lines.isEmpty {
            size -= lines.removeFirst().count + 1
        }
        return lines
    }

    private func writeLines(_ lines: [Data], to url: URL) throws {
        var output = Data()
        for line in lines {
            output.append(line)
            output.append(0x0A)
        }
        try writeSynced(output, to: url)
    }

    private func writeSynced(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.synchronize()
    }
}

private extension GameCommandAction {
    var isStartCommand: Bool {
        if case .startSession = self { return true }
        return false
    }
}
