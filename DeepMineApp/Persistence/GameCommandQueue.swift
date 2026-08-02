import DeepMineCore
import Foundation
import SwiftData
struct QuarantinedGameCommand: Codable, Equatable, Sendable {
    let rawLine: String
    let reason: String
    let quarantinedAt: Date
}
struct GameCommandDrainReport: Equatable, Sendable {
    var applied = 0, duplicates = 0, conflicts = 0
    var quarantined = 0, deferred = 0
}
struct GameCommandQueue: Sendable {
    static let queueFilename = GameCommandEnqueuer.queueFilename,
               lockFilename = GameCommandEnqueuer.lockFilename,
               receiptFilename = GameCommandEnqueuer.receiptFilename
    static let quarantineFilename = "GameCommands.quarantine.jsonl"
    static let corruptReceiptDirectory = GameCommandEnqueuer.corruptReceiptDirectory
    static let appGroupIdentifier = "group.com.eiraworks.deepmine"
    static let maximumBytes = GameCommandEnqueuer.maximumBytes,
               retainedCommandCount = GameCommandEnqueuer.retainedCount
    let directoryURL: URL
    let maximumBytes: Int, retainedCount: Int
    let beforeWrite: (@Sendable (URL) throws -> Void)?
    init(directoryURL: URL, maximumBytes: Int = Self.maximumBytes,
         retainedCount: Int = Self.retainedCommandCount,
         beforeWrite: (@Sendable (URL) throws -> Void)? = nil) {
        self.directoryURL = directoryURL
        self.maximumBytes = maximumBytes
        self.retainedCount = retainedCount
        self.beforeWrite = beforeWrite
    }
    static func shared(fileManager: FileManager = .default) throws -> GameCommandQueue {
        guard let directory = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw GamePersistenceError.appGroupUnavailable(appGroupIdentifier)
        }
        return GameCommandQueue(directoryURL: directory)
    }
    @discardableResult func enqueue(
        _ command: GameCommand, now: Date = Date()
    ) throws -> GameCommandEnqueueResult {
        try GameCommandEnqueuer(
            directoryURL: directoryURL,
            maximumBytes: maximumBytes,
            retainedCount: retainedCount
        ).enqueue(command, now: now)
    }
    func pendingCommands() throws -> [GameCommand] {
        let lock = try acquireLock()
        defer { lock.release() }
        return try readLines(at: queueURL).compactMap { try? decodeCommand($0) }
    }
    func receipts() throws -> [GameCommandReceipt] {
        let lock = try acquireLock()
        defer { lock.release() }
        return try readReceipts()
    }
    @MainActor
    func drain(
        into repository: GameRepository,
        now: @escaping @Sendable () -> Date = Date.init,
        afterRepositoryCommit: ((GameCommand) throws -> Void)? = nil,
        sessionHandler: ((GameCommand) throws -> Bool)? = nil
    ) throws -> GameCommandDrainReport {
        let lock = try acquireLock()
        defer { lock.release() }
        let lines = try readLines(at: queueURL)
        var remaining: [Data] = []
        var quarantine = try readLines(at: quarantineURL)
        var receipts = try readReceipts()
        var report = GameCommandDrainReport()
        let mirrored = Set(receipts.map(\.commandID))
        for id in try repository.appliedCommandIDs() where !mirrored.contains(id) {
            upsertReceipt(id, state: .applied, at: now(), in: &receipts)
        }
        try writeReceipts(receipts)
        for line in lines {
            let command: GameCommand
            do {
                command = try decodeCommand(line)
            } catch {
                let rawLine = String(String(decoding: line, as: UTF8.self).prefix(2_048))
                let record = QuarantinedGameCommand(
                    rawLine: rawLine,
                    reason: "invalid-json",
                    quarantinedAt: now()
                )
                let isRecorded = quarantine.contains {
                    (try? decoder().decode(QuarantinedGameCommand.self, from: $0))?.rawLine == rawLine
                }
                if !isRecorded { quarantine.append(try encodeLine(record)) }
                report.quarantined += 1
                continue
            }
            if receipts.last(where: { $0.commandID == command.id })?.state == .applied {
                report.duplicates += 1
                continue
            }
            if command.action.isSessionCommand, let sessionHandler {
                upsertReceipt(command.id, state: .applying, at: now(), in: &receipts)
                try writeReceipts(receipts)
                if try sessionHandler(command) {
                    upsertReceipt(command.id, state: .applied, at: now(), in: &receipts)
                    try writeReceipts(receipts)
                    report.applied += 1
                    continue
                }
                if command.action.isStartCommand {
                    upsertReceipt(command.id, state: .applied, at: now(), in: &receipts)
                    try writeReceipts(receipts)
                    report.conflicts += 1
                    continue
                }
                upsertReceipt(command.id, state: .pending, at: now(), in: &receipts)
                try writeReceipts(receipts)
            }
            guard command.action.isRepositoryCommand else {
                remaining.append(line)
                report.deferred += 1
                continue
            }
            upsertReceipt(command.id, state: .applying, at: now(), in: &receipts)
            try writeReceipts(receipts)
            let applied = try repository.applyAtomically(command)
            try afterRepositoryCommit?(command)
            upsertReceipt(command.id, state: .applied, at: now(), in: &receipts)
            try writeReceipts(receipts)
            if applied { report.applied += 1 } else { report.duplicates += 1 }
        }
        try writeLines(bounded(quarantine), to: quarantineURL)
        try writeLines(bounded(remaining), to: queueURL)
        return report
    }

    private var queueURL: URL { directoryURL.appending(path: Self.queueFilename) }
    private var receiptURL: URL { directoryURL.appending(path: Self.receiptFilename) }
    private var quarantineURL: URL { directoryURL.appending(path: Self.quarantineFilename) }
    private func acquireLock() throws -> ProbeProcessLock {
        try ProbeProcessLock.acquire(filename: Self.lockFilename, directoryURL: directoryURL) }
    private func readLines(at url: URL) throws -> [Data] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try [UInt8](Data(contentsOf: url))
            .split(separator: UInt8(0x0A), omittingEmptySubsequences: true)
            .map { Data($0) }
    }
    private func writeLines(_ lines: [Data], to url: URL) throws {
        var data = Data()
        for line in lines {
            data.append(line)
            data.append(0x0A)
        }
        try writeData(data, to: url)
    }
    private func bounded(_ lines: [Data]) -> [Data] {
        var result = Array(lines.suffix(retainedCount))
        var size = result.reduce(0) { $0 + $1.count + 1 }
        while size > maximumBytes, !result.isEmpty {
            size -= result.removeFirst().count + 1
        }
        return result
    }
    private func readReceipts() throws -> [GameCommandReceipt] {
        guard FileManager.default.fileExists(atPath: receiptURL.path) else { return [] }
        do {
            return try decoder().decode([GameCommandReceipt].self, from: Data(contentsOf: receiptURL))
        } catch {
            let directory = directoryURL.appending(path: Self.corruptReceiptDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let destination = directory.appending(path: "AppliedCommands-\(UUID().uuidString).json")
            try FileManager.default.moveItem(at: receiptURL, to: destination)
            return []
        }
    }
    private func writeReceipts(_ receipts: [GameCommandReceipt]) throws {
        let live = Array(receipts.filter { $0.state != .applied }.suffix(retainedCount))
        let capacity = max(0, retainedCount - live.count)
        let applied = Array(receipts.filter { $0.state == .applied }.suffix(capacity))
        let bounded = applied + live
        try writeData(encoder().encode(bounded), to: receiptURL)
    }
    private func writeData(_ data: Data, to url: URL) throws {
        try beforeWrite?(url)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.synchronize()
    }
    private func upsertReceipt(_ id: UUID, state: GameCommandReceiptState,
                               at date: Date, in receipts: inout [GameCommandReceipt]) {
        if let index = receipts.firstIndex(where: { $0.commandID == id }) {
            receipts.remove(at: index)
        }
        receipts.append(GameCommandReceipt(commandID: id, state: state, updatedAt: date))
    }
    private func encodeLine<Value: Encodable>(_ value: Value) throws -> Data {
        try encoder().encode(value) }
    private func decodeCommand(_ data: Data) throws -> GameCommand {
        try decoder().decode(GameCommand.self, from: data) }
    private func encoder() -> JSONEncoder { JSONEncoder() }
    private func decoder() -> JSONDecoder { JSONDecoder() }
}

private extension GameCommandAction {
    var isStartCommand: Bool { if case .startSession = self { true } else { false } }
    var isSessionCommand: Bool {
        switch self {
        case .startSession, .abandonSession: true
        case .upgradeEquipment, .purchasePermanentUpgrade, .prestige, .open: false
        }
    }
    var isRepositoryCommand: Bool {
        switch self {
        case .upgradeEquipment, .purchasePermanentUpgrade, .prestige: true
        case .startSession, .abandonSession, .open: false
        }
    }
}

@MainActor
extension GameRepository {
    func replaceState(
        _ state: PlayerState, commandReceipts: Set<UUID>, in context: ModelContext
    ) throws {
        for item in try context.fetch(FetchDescriptor<PlayerStateEntity>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<EquipmentStateEntity>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<SessionRecordEntity>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<DailyRecordEntity>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<PurchaseStateEntity>()) { context.delete(item) }
        let root = PlayerStateEntity()
        root.apply(state)
        root.appliedCompletionIDsData = try encodeUUIDs(state.appliedCompletionIDs)
        root.usedRestWeeksData = try JSONEncoder().encode(Array(state.usedRestWeeks))
        root.unlockedThemesData = try JSONEncoder().encode(Array(state.unlockedThemes))
        root.unlockedDecorationsData = try JSONEncoder().encode(Array(state.unlockedDecorations))
        root.appliedVeinEffectIDsData = try encodeUUIDs(state.appliedVeinEffectIDs)
        root.appliedPrestigeCommandIDsData = try encodeUUIDs(state.appliedPrestigeCommandIDs)
        root.earnedAchievementIDsData = try encodeSet(state.earnedAchievementIDs)
        context.insert(root)
        let equipment = EquipmentStateEntity()
        equipment.drillLevel = state.equipment.drill
        equipment.cartLevel = state.equipment.cart
        equipment.lampLevel = state.equipment.lamp
        equipment.rememberedDrillLevel = state.rememberedEquipment.drill
        equipment.rememberedCartLevel = state.rememberedEquipment.cart
        equipment.rememberedLampLevel = state.rememberedEquipment.lamp
        equipment.drillRefinementTier = state.refinementTiers.drill
        equipment.cartRefinementTier = state.refinementTiers.cart
        equipment.lampRefinementTier = state.refinementTiers.lamp
        context.insert(equipment)
        for (index, record) in state.history.enumerated() {
            let entity = SessionRecordEntity(completionID: record.completionID)
            entity.apply(record, sortIndex: index)
            context.insert(entity)
        }
        for (index, record) in state.dailyRecords.enumerated() {
            let entity = DailyRecordEntity(
                year: record.dayKey.year, month: record.dayKey.month, day: record.dayKey.day
            )
            entity.apply(record, sortIndex: index)
            context.insert(entity)
        }
        let purchases = PurchaseStateEntity()
        purchases.appliedPurchaseIDsData = try encodeUUIDs(state.appliedPurchaseIDs)
        purchases.appliedPermanentUpgradeCommandIDsData = try encodeUUIDs(
            state.appliedPermanentUpgradeCommandIDs
        )
        purchases.appliedGameCommandIDsData = try encodeUUIDs(commandReceipts)
        context.insert(purchases)
    }
    func encodeUUIDs(_ values: Set<UUID>) throws -> Data {
        try JSONEncoder().encode(Array(values)) }
    func decodeUUIDs(_ data: Data?) throws -> Set<UUID> {
        guard let data, !data.isEmpty else { return [] }
        return Set(try JSONDecoder().decode([UUID].self, from: data)) }
}
