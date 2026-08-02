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
        let commandReceipts = try decodeUUIDs(
            context.fetch(FetchDescriptor<PurchaseStateEntity>())
                .first?.appliedGameCommandIDsData
        )
        try replaceState(state, commandReceipts: commandReceipts, in: context)
        try context.save()
    }
    func appliedCommandIDs() throws -> Set<UUID> {
        let context = ModelContext(modelContainer)
        return try decodeUUIDs(context.fetch(
            FetchDescriptor<PurchaseStateEntity>()
        ).first?.appliedGameCommandIDsData)
    }
    func applyAtomically(_ command: GameCommand) throws -> Bool {
        let context = ModelContext(modelContainer)
        let existing = try context.fetch(FetchDescriptor<PurchaseStateEntity>()).first
        var receipts = try decodeUUIDs(existing?.appliedGameCommandIDsData)
        guard receipts.insert(command.id).inserted else { return false }
        var state = try load()
        switch command.action {
        case let .upgradeEquipment(kind):
            _ = EquipmentEngine.purchase(
                UpgradePurchaseCommand(id: command.id, equipment: kind), in: &state
            )
        case let .purchasePermanentUpgrade(kind):
            _ = PrestigeEngine.purchase(
                PermanentUpgradeCommand(id: command.id, upgrade: kind), in: &state
            )
        case .prestige:
            _ = PrestigeEngine.prestige(PrestigeCommand(id: command.id), in: &state)
        case .startSession, .abandonSession, .open:
            return false
        }
        try replaceState(state, commandReceipts: receipts, in: context)
        try context.save()
        return true
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
            resources: Resources(
                ore: root.storedOre,
                crystals: root.crystals,
                coreShards: root.coreShards
            ),
            equipment: EquipmentLevels(drill: equipment.drillLevel, cart: equipment.cartLevel, lamp: equipment.lampLevel),
            rememberedEquipment: EquipmentLevels(
                drill: equipment.rememberedDrillLevel,
                cart: equipment.rememberedCartLevel,
                lamp: equipment.rememberedLampLevel
            ),
            equipmentModifications: root.storedEquipmentModifications(),
            refinementTiers: RefinementTiers(
                drill: equipment.drillRefinementTier,
                cart: equipment.cartRefinementTier,
                lamp: equipment.lampRefinementTier
            ),
            runFocusCredits: root.runFocusCredits,
            lifetimeFocusCredits: root.lifetimeFocusCredits,
            runSegmentsBroken: root.runSegmentsBroken,
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
            earnedAchievementIDs: root.earnedAchievementIDsData.isEmpty
                ? []
                : try decodeSet(root.earnedAchievementIDsData),
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
            ),
            mineFace: root.storedMineFace(),
            deepestSegmentIndex: root.deepestSegmentIndex,
            lastSettledAt: root.lastSettledAt
        )
    }
    private func requireOne<T>(_ values: [T], named name: String) throws -> T {
        guard values.count == 1, let value = values.first else {
            throw GamePersistenceError.missingEntity(name)
        }
        return value
    }

}
