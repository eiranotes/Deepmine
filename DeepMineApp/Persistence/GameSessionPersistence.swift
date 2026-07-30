import DeepMineCore
import Foundation
import SwiftData

enum GameStoreError: Error, Equatable {
    case sessionAlreadyActive
    case noActiveSession
}

func gameSessionSeed(for id: UUID) -> UInt64 {
    withUnsafeBytes(of: id.uuid) { bytes in
        bytes.prefix(8).reduce(0) { ($0 << 8) | UInt64($1) }
    }
}

struct AbandonSnapshot: Codable, Equatable, Sendable {
    let requestedAt: Date
    let elapsedMinutes: Int
    let clockAssessment: DeepMineCore.ClockIntegrityAssessment
    let verificationGrade: VerificationGrade
}

struct PersistedGameSession: Codable, Equatable, Sendable {
    let id: UUID
    let completionID: UUID
    let originCommandID: UUID?
    let length: SessionLength
    let plan: MinePlan
    let startedAt: Date
    let endsAt: Date
    let clockAnchor: DeepMineCore.ClockAnchor
    let randomSeed: UInt64
    var phase: SessionPhase
    var systemsConfigured: Bool
    var abandonRequested: Bool
    var abandonSnapshot: AbandonSnapshot?
    var blockingEnabled: Bool
    var shieldMaintained: Bool
    var forcedShieldRemoval: Bool
    var forcedRemovalPending: Bool
    var openReason: String?
    var alarmDelivery: SessionAlarmDelivery
    var liveActivityID: String?
    var warnings: [String]

    mutating func recordForcedRemovalResult(succeeded: Bool) -> String {
        let retry = "집중 차단 해제를 완료하지 못해 다음 활성화 때 다시 시도합니다."
        if succeeded {
            forcedRemovalPending = false
            warnings.removeAll { $0 == retry }
            return "집중 차단이 강제로 해제되어 붕괴 등급으로 기록됩니다."
        }
        if !warnings.contains(retry) { warnings.append(retry) }
        warnings = Array(warnings.prefix(8))
        return retry
    }
}

struct GameStoreDiagnostic: Equatable, Sendable {
    let activeSession: PersistedGameSession?
    let returnReport: GameReturnReport?
    let visibleReason: String?
}

@Model
final class GameSessionEntity {
    @Attribute(.unique) var id: UUID
    var schemaVersion: Int
    var activeSessionData: Data?
    var returnReportData: Data?

    init(schemaVersion: Int = GameSchemaV1.version) {
        id = GameSchemaV1.singletonID
        self.schemaVersion = schemaVersion
    }
}

@MainActor
protocol GameSessionRepository: AnyObject {
    func loadPlayer() throws -> PlayerState
    func savePlayer(_ player: PlayerState) throws
    func loadActiveSession() throws -> PersistedGameSession?
    func loadReturnReport() throws -> GameReturnReport?
    func clearReturnReport() throws
    func saveActiveSession(_ session: PersistedGameSession, commandID: UUID?) throws
    func markCommandApplied(_ commandID: UUID) throws
    func commitSession(
        player: PlayerState,
        report: GameReturnReport,
        cleanupSession: PersistedGameSession
    ) throws
    func finishSessionCleanup(report: GameReturnReport) throws
}

@MainActor
extension GameRepository: GameSessionRepository {
    func loadPlayer() throws -> PlayerState { try load() }
    func savePlayer(_ player: PlayerState) throws { try save(player) }

    func loadActiveSession() throws -> PersistedGameSession? {
        try lifecycleEntity()?.activeSessionData.map {
            try JSONDecoder().decode(PersistedGameSession.self, from: $0)
        }
    }

    func loadReturnReport() throws -> GameReturnReport? {
        try lifecycleEntity()?.returnReportData.map {
            try JSONDecoder().decode(GameReturnReport.self, from: $0)
        }
    }

    func clearReturnReport() throws {
        let context = ModelContext(modelContainer)
        guard let entity = try context.fetch(FetchDescriptor<GameSessionEntity>()).first else {
            return
        }
        entity.returnReportData = nil
        try context.save()
    }

    func saveActiveSession(_ session: PersistedGameSession, commandID: UUID?) throws {
        let context = ModelContext(modelContainer)
        let entity = try context.fetch(FetchDescriptor<GameSessionEntity>()).first
            ?? GameSessionEntity()
        if entity.modelContext == nil { context.insert(entity) }
        entity.activeSessionData = try JSONEncoder().encode(session)
        if let commandID,
           let purchases = try context.fetch(FetchDescriptor<PurchaseStateEntity>()).first {
            var receipts = try decodeUUIDs(purchases.appliedGameCommandIDsData)
            receipts.insert(commandID)
            purchases.appliedGameCommandIDsData = try encodeUUIDs(receipts)
        }
        try context.save()
    }

    func markCommandApplied(_ commandID: UUID) throws {
        let context = ModelContext(modelContainer)
        guard let purchases = try context.fetch(FetchDescriptor<PurchaseStateEntity>()).first else {
            throw GamePersistenceError.missingEntity("PurchaseStateEntity")
        }
        var receipts = try decodeUUIDs(purchases.appliedGameCommandIDsData)
        receipts.insert(commandID)
        purchases.appliedGameCommandIDsData = try encodeUUIDs(receipts)
        try context.save()
    }

    func commitSession(
        player: PlayerState,
        report: GameReturnReport,
        cleanupSession: PersistedGameSession
    ) throws {
        let context = ModelContext(modelContainer)
        let purchases = try context.fetch(FetchDescriptor<PurchaseStateEntity>()).first
        let receipts = try decodeUUIDs(purchases?.appliedGameCommandIDsData)
        try replaceState(player, commandReceipts: receipts, in: context)
        try context.delete(model: GameSessionEntity.self)
        let entity = GameSessionEntity()
        entity.activeSessionData = try JSONEncoder().encode(cleanupSession)
        entity.returnReportData = try JSONEncoder().encode(report)
        context.insert(entity)
        try context.save()
    }

    func finishSessionCleanup(report: GameReturnReport) throws {
        let context = ModelContext(modelContainer)
        guard let entity = try context.fetch(FetchDescriptor<GameSessionEntity>()).first else {
            throw GamePersistenceError.missingEntity("GameSessionEntity")
        }
        entity.activeSessionData = nil
        entity.returnReportData = try JSONEncoder().encode(report)
        try context.save()
    }

    func validateSessionLifecycle() throws {
        _ = try lifecycleEntity()
    }

    private func lifecycleEntity() throws -> GameSessionEntity? {
        let values = try modelContainer.mainContext.fetch(FetchDescriptor<GameSessionEntity>())
        guard values.count <= 1 else {
            throw GamePersistenceError.missingEntity("GameSessionEntity")
        }
        guard let value = values.first else { return nil }
        guard value.schemaVersion == GameSchemaV1.version else {
            throw GamePersistenceError.unsupportedSchemaVersion(
                entity: "GameSessionEntity", found: value.schemaVersion
            )
        }
        if let data = value.activeSessionData {
            _ = try JSONDecoder().decode(PersistedGameSession.self, from: data)
        }
        if let data = value.returnReportData {
            _ = try JSONDecoder().decode(GameReturnReport.self, from: data)
        }
        return value
    }
}
