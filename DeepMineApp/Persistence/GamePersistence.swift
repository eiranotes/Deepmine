import DeepMineCore
import Foundation
import SwiftData
enum GamePersistenceError: Error, Equatable {
    case appGroupUnavailable(String)
    case unsupportedSchemaVersion(entity: String, found: Int)
    case missingEntity(String)
    case invalidStoredValue(field: String, value: String)
}
struct GameRecoveryNotice: Identifiable, Equatable {
    let quarantineURL: URL
    var id: URL { quarantineURL }
    let message = "저장 데이터 문제를 감지해 원본을 격리하고 새 게임을 시작했습니다."
}
enum StoreQuarantineCoordinator {
    static func storeFamilyURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]
    }
    @discardableResult
    static func quarantine(storeURL: URL, now: Date = Date(), fileManager: FileManager = .default) throws -> URL? {
        let existing = storeFamilyURLs(for: storeURL).filter {
            fileManager.fileExists(atPath: $0.path)
        }
        guard !existing.isEmpty else { return nil }
        let root = storeURL.deletingLastPathComponent().appending(path: "CorruptStores")
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let timestamp = String(Int64((now.timeIntervalSince1970 * 1_000).rounded()))
        var destination = root.appending(path: timestamp)
        var suffix = 1
        while fileManager.fileExists(atPath: destination.path) {
            destination = root.appending(path: "\(timestamp)-\(suffix)")
            suffix += 1
        }
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        var moved: [(source: URL, destination: URL)] = []
        do {
            for source in existing {
                let target = destination.appending(path: source.lastPathComponent)
                try fileManager.moveItem(at: source, to: target)
                moved.append((source, target))
            }
        } catch {
            for item in moved.reversed() {
                try? fileManager.moveItem(at: item.destination, to: item.source)
            }
            throw error
        }
        return destination
    }
}
@MainActor
final class GameRepository {
    static let currentSchemaVersion = GameSchemaV1.version
    static let appGroupIdentifier = "group.com.eiraworks.deepmine"
    static let storeFilename = "DeepMine.store"
    private(set) var modelContainer: ModelContainer
    let recoveryNotice: GameRecoveryNotice?
    private init(container: ModelContainer, recoveryNotice: GameRecoveryNotice? = nil) {
        modelContainer = container
        self.recoveryNotice = recoveryNotice
    }
    static func openShared() throws -> GameRepository {
        guard let directory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw GamePersistenceError.appGroupUnavailable(appGroupIdentifier)
        }
        return try open(storeURL: directory.appending(path: storeFilename))
    }
    static func open(storeURL: URL) throws -> GameRepository {
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        do {
            let repository = try configuredRepository(storeURL: storeURL)
            _ = try repository.load()
            return repository
        } catch let error as GamePersistenceError where error.isUnsupportedSchema {
            throw error
        } catch {
            guard let quarantineURL = try StoreQuarantineCoordinator.quarantine(storeURL: storeURL)
            else { throw error }
            let repository = try configuredRepository(
                storeURL: storeURL,
                recoveryNotice: GameRecoveryNotice(quarantineURL: quarantineURL)
            )
            _ = try repository.load()
            return repository
        }
    }
    static func inMemory() throws -> GameRepository {
        let configuration = ModelConfiguration(
            "DeepMineGameTests",
            schema: GameSchemaV1.schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: GameSchemaV1.schema,
            configurations: [configuration]
        )
        return GameRepository(container: container)
    }
    func load() throws -> PlayerState {
        try validateSessionLifecycle()
        let context = modelContainer.mainContext
        let roots = try context.fetch(FetchDescriptor<PlayerStateEntity>())
        guard !roots.isEmpty else {
            let state = PlayerState()
            try save(state)
            return state
        }
        let root = try requireOne(roots, named: "PlayerStateEntity")
        let equipment = try requireOne(
            context.fetch(FetchDescriptor<EquipmentStateEntity>()),
            named: "EquipmentStateEntity"
        )
        let purchases = try requireOne(
            context.fetch(FetchDescriptor<PurchaseStateEntity>()),
            named: "PurchaseStateEntity"
        )
        var sessionDescriptor = FetchDescriptor<SessionRecordEntity>(
            sortBy: [SortDescriptor(\SessionRecordEntity.sortIndex)]
        )
        sessionDescriptor.fetchLimit = 500
        let sessions = try context.fetch(sessionDescriptor)
        let daily = try context.fetch(
            FetchDescriptor<DailyRecordEntity>(sortBy: [SortDescriptor(\DailyRecordEntity.sortIndex)])
        )
        try validateVersions(root: root, equipment: equipment, sessions: sessions, daily: daily, purchases: purchases)
        return try makeState(root: root, equipment: equipment, sessions: sessions, daily: daily, purchases: purchases)
    }
    func save(_ state: PlayerState) throws {
        let context = ModelContext(modelContainer)
        let commandReceipts = try context.fetch(FetchDescriptor<PurchaseStateEntity>())
            .first?.appliedGameCommandIDsData ?? Data("[]".utf8)
        try deleteAll(from: context)
        let root = PlayerStateEntity()
        root.apply(state)
        root.appliedCompletionIDsData = try encodeSet(state.appliedCompletionIDs)
        root.usedRestWeeksData = try encodeSet(state.usedRestWeeks)
        root.unlockedThemesData = try encodeSet(state.unlockedThemes)
        root.unlockedDecorationsData = try encodeSet(state.unlockedDecorations)
        root.appliedVeinEffectIDsData = try encodeSet(state.appliedVeinEffectIDs)
        root.appliedPrestigeCommandIDsData = try encodeSet(state.appliedPrestigeCommandIDs)
        context.insert(root)
        let equipment = EquipmentStateEntity()
        equipment.drillLevel = state.equipment.drill
        equipment.cartLevel = state.equipment.cart
        equipment.lampLevel = state.equipment.lamp
        context.insert(equipment)
        for (index, record) in state.history.enumerated() {
            let entity = SessionRecordEntity(completionID: record.completionID)
            entity.apply(record, sortIndex: index)
            context.insert(entity)
        }
        for (index, record) in state.dailyRecords.enumerated() {
            let entity = DailyRecordEntity(
                year: record.dayKey.year,
                month: record.dayKey.month,
                day: record.dayKey.day
            )
            entity.apply(record, sortIndex: index)
            context.insert(entity)
        }
        let purchases = PurchaseStateEntity()
        purchases.appliedPurchaseIDsData = try encodeSet(state.appliedPurchaseIDs)
        purchases.appliedPermanentUpgradeCommandIDsData = try encodeSet(
            state.appliedPermanentUpgradeCommandIDs
        )
        purchases.appliedGameCommandIDsData = commandReceipts
        context.insert(purchases)
        try context.save()
    }
    private static func configuredRepository(
        storeURL: URL, recoveryNotice: GameRecoveryNotice? = nil
    ) throws -> GameRepository {
        let configuration = ModelConfiguration(
            "DeepMineGame",
            schema: GameSchemaV1.schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: GameSchemaV1.schema,
            configurations: [configuration]
        )
        return GameRepository(container: container, recoveryNotice: recoveryNotice)
    }
    private func makeState(
        root: PlayerStateEntity,
        equipment: EquipmentStateEntity,
        sessions: [SessionRecordEntity],
        daily: [DailyRecordEntity],
        purchases: PurchaseStateEntity
    ) throws -> PlayerState {
        PlayerState(
            resources: Resources(ore: root.ore, crystals: root.crystals, coreShards: root.coreShards),
            equipment: EquipmentLevels(drill: equipment.drillLevel, cart: equipment.cartLevel, lamp: equipment.lampLevel),
            runFocusCredits: root.runFocusCredits,
            lifetimeFocusCredits: root.lifetimeFocusCredits,
            completedSessionCount: root.completedSessionCount,
            bonusDepthMeters: root.bonusDepthMeters,
            history: try sessions.map { try $0.coreRecord() },
            appliedCompletionIDs: try decodeSet(root.appliedCompletionIDsData),
            appliedPurchaseIDs: try decodeSet(purchases.appliedPurchaseIDsData),
            dailyGoalMinutes: root.dailyGoalMinutes,
            streakDays: root.streakDays,
            dailyRecords: daily.map { $0.coreRecord() },
            usedRestWeeks: try decodeSet(root.usedRestWeeksData),
            latestDayKey: try root.latestDayKey(),
            consecutiveVeinMisses: root.consecutiveVeinMisses,
            permanentResonanceLevel: root.permanentResonanceLevel,
            unlockedThemes: try decodeSet(root.unlockedThemesData),
            selectedTheme: try value(MineTheme.self, rawValue: root.selectedThemeRawValue, field: "selectedTheme"),
            unlockedDecorations: try decodeSet(root.unlockedDecorationsData),
            resonanceBoostPending: root.resonanceBoostPending,
            appliedVeinEffectIDs: try decodeSet(root.appliedVeinEffectIDsData),
            excavationMemoryLevel: root.excavationMemoryLevel,
            compressedTimeLevel: root.compressedTimeLevel,
            prestigeIndex: root.prestigeIndex,
            appliedPrestigeCommandIDs: try decodeSet(root.appliedPrestigeCommandIDsData),
            appliedPermanentUpgradeCommandIDs: try decodeSet(purchases.appliedPermanentUpgradeCommandIDsData),
            onboardingStage: try value(
                OnboardingStage.self,
                rawValue: root.onboardingStageRawValue,
                field: "onboardingStage"
            ),
            demoStartedAt: root.demoStartedAt,
            demoCompletedAt: root.demoCompletedAt,
            demoRewardReceiptID: root.demoRewardReceiptID,
            demoUpgradePurchaseID: root.demoUpgradePurchaseID,
            focusProtectionPermission: try value(
                OnboardingPermissionOutcome.self,
                rawValue: root.focusProtectionPermissionRawValue,
                field: "focusProtectionPermission"
            ),
            endAlertPermission: try value(
                OnboardingPermissionOutcome.self,
                rawValue: root.endAlertPermissionRawValue,
                field: "endAlertPermission"
            ),
            returnReminderPermission: try value(
                OnboardingPermissionOutcome.self,
                rawValue: root.returnReminderPermissionRawValue,
                field: "returnReminderPermission"
            ),
            lastSelectedPlan: try value(
                MinePlan.self,
                rawValue: root.lastSelectedPlanRawValue,
                field: "lastSelectedPlan"
            ),
            lastSelectedDuration: try value(
                SessionLength.self,
                rawValue: root.lastSelectedDurationRawValue,
                field: "lastSelectedDuration"
            )
        )
    }
    private func deleteAll(from context: ModelContext) throws {
        try context.delete(model: PlayerStateEntity.self)
        try context.delete(model: EquipmentStateEntity.self)
        try context.delete(model: SessionRecordEntity.self)
        try context.delete(model: DailyRecordEntity.self)
        try context.delete(model: PurchaseStateEntity.self)
    }
    private func requireOne<T>(_ values: [T], named name: String) throws -> T {
        guard values.count == 1, let value = values.first else {
            throw GamePersistenceError.missingEntity(name)
        }
        return value
    }

    private func validateVersions(
        root: PlayerStateEntity,
        equipment: EquipmentStateEntity,
        sessions: [SessionRecordEntity],
        daily: [DailyRecordEntity],
        purchases: PurchaseStateEntity
    ) throws {
        try validate(root.schemaVersion, entity: "PlayerStateEntity")
        try validate(equipment.schemaVersion, entity: "EquipmentStateEntity")
        try sessions.forEach { try validate($0.schemaVersion, entity: "SessionRecordEntity") }
        try daily.forEach { try validate($0.schemaVersion, entity: "DailyRecordEntity") }
        try validate(purchases.schemaVersion, entity: "PurchaseStateEntity")
    }

    private func validate(_ version: Int, entity: String) throws {
        guard version == Self.currentSchemaVersion else {
            throw GamePersistenceError.unsupportedSchemaVersion(entity: entity, found: version)
        }
    }
}
