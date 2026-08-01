import DeepMineCore
import Foundation
import SwiftData
import XCTest
@testable import DeepMine

@MainActor
final class GamePersistenceTests: XCTestCase {
    func testFullPlayerStateRoundTripsAcrossRepositoryReload() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "DeepMine.store")
        let completionID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let purchaseID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let veinEffectID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        let prestigeID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
        let upgradeID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
        let state = PlayerState(
            resources: Resources(ore: 12_345.5, crystals: 17, coreShards: 4),
            equipment: EquipmentLevels(drill: 8, cart: 6, lamp: 5),
            equipmentModifications: EquipmentModifications(
                drill: .drillWide,
                cart: .cartFreight,
                lamp: .lampReach
            ),
            runFocusCredits: 31.5,
            lifetimeFocusCredits: 94.25,
            runSegmentsBroken: 88,
            completedSessionCount: 18,
            bonusDepthMeters: 240,
            history: [
                SessionHistoryEntry(
                    completionID: completionID,
                    endedAt: Date(timeIntervalSince1970: 1_750_000_000),
                    focusedMinutes: 50,
                    focusCredits: 2,
                    plan: .deep,
                    verificationGrade: .sealed,
                    oreEarned: 1_234.5,
                    vein: .abyss,
                    depthAfter: 3_210,
                    completed: true
                )
            ],
            appliedCompletionIDs: [completionID],
            appliedPurchaseIDs: [purchaseID],
            dailyGoalMinutes: 75,
            streakDays: 12,
            dailyRecords: [
                DailyRecord(
                    dayKey: DayKey(year: 2026, month: 7, day: 29),
                    focusedMinutes: 75,
                    goalMinutes: 75,
                    sessionCount: 2,
                    goalEarned: true,
                    streakApplied: true,
                    wasRestDay: false,
                    isFinalized: true
                )
            ],
            usedRestWeeks: [ISOWeekKey(yearForWeekOfYear: 2026, weekOfYear: 30)],
            latestDayKey: DayKey(year: 2026, month: 7, day: 29),
            consecutiveVeinMisses: 3,
            permanentResonanceLevel: 2,
            unlockedThemes: [.entry, .crystal, .ruins],
            selectedTheme: .ruins,
            unlockedDecorations: [.marker, .rail],
            resonanceBoostPending: true,
            appliedVeinEffectIDs: [veinEffectID],
            excavationMemoryLevel: 3,
            compressedTimeLevel: 1,
            prestigeIndex: 2,
            appliedPrestigeCommandIDs: [prestigeID],
            appliedPermanentUpgradeCommandIDs: [upgradeID],
            onboardingStage: .permissions,
            demoStartedAt: Date(timeIntervalSince1970: 1_749_999_800),
            demoCompletedAt: Date(timeIntervalSince1970: 1_749_999_890),
            demoRewardReceiptID: UUID(uuidString: "00000000-0000-0000-0000-000000000006"),
            demoUpgradePurchaseID: UUID(uuidString: "00000000-0000-0000-0000-000000000007"),
            focusProtectionPermission: .denied,
            endAlertPermission: .deferred,
            returnReminderPermission: .granted,
            lastSelectedPlan: .survey,
            lastSelectedDuration: .minutes50,
            // The clicker's position. It was absent from the store entirely, so every
            // tap between one break and the next launch was silently dropped and the
            // player restarted at the surface.
            mineFace: MineFaceState(
                segmentIndex: 412,
                remainingIntegrity: RockGenerator.segment(at: 412).maximumIntegrity / 3,
                impact: ImpactMeter(value: 42),
                lifetimeSegmentsBroken: 1_902,
                lifetimeSeamsBroken: 74,
                boreHistory: [
                    BoreRecord(
                        segmentIndex: 410,
                        drillLevel: 7,
                        cartLevel: 5,
                        lampLevel: 4
                    ),
                    BoreRecord(
                        segmentIndex: 411,
                        drillLevel: 8,
                        cartLevel: 6,
                        lampLevel: 5,
                        drillModification: .drillWide
                    )
                ]
            ),
            deepestSegmentIndex: 690,
            lastSettledAt: Date(timeIntervalSince1970: 1_750_000_500)
        )

        var repository: GameRepository? = try GameRepository.open(storeURL: storeURL)
        try repository?.save(state)
        repository = nil
        let reloaded = try GameRepository.open(storeURL: storeURL)

        XCTAssertEqual(try reloaded.load(), state)
    }

    func testEmptyStoreCreatesAndReturnsDefaults() throws {
        let repository = try GameRepository.inMemory()

        XCTAssertEqual(try repository.load(), PlayerState())
        XCTAssertEqual(
            try repository.modelContainer.mainContext.fetchCount(
                FetchDescriptor<PlayerStateEntity>()
            ),
            1
        )
    }

    func testOnboardingSchemaFieldsHaveSafeV1Defaults() {
        let entity = PlayerStateEntity()

        XCTAssertEqual(entity.onboardingStageRawValue, OnboardingStage.premiseBlocks.rawValue)
        XCTAssertNil(entity.demoStartedAt)
        XCTAssertNil(entity.demoCompletedAt)
        XCTAssertNil(entity.demoRewardReceiptID)
        XCTAssertNil(entity.demoUpgradePurchaseID)
        XCTAssertEqual(entity.focusProtectionPermissionRawValue, OnboardingPermissionOutcome.notAsked.rawValue)
        XCTAssertEqual(entity.endAlertPermissionRawValue, OnboardingPermissionOutcome.notAsked.rawValue)
        XCTAssertEqual(entity.returnReminderPermissionRawValue, OnboardingPermissionOutcome.notAsked.rawValue)
        XCTAssertEqual(entity.lastSelectedPlanRawValue, MinePlan.safe.rawValue)
        XCTAssertEqual(entity.lastSelectedDurationRawValue, SessionLength.minutes25.rawValue)
        XCTAssertTrue(entity.equipmentModificationsData.isEmpty)
        XCTAssertTrue(entity.mineFaceBoreHistoryData.isEmpty)
    }

    func testUnsupportedSchemaVersionFailsClosed() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "DeepMine.store")
        let repository = try GameRepository.open(storeURL: storeURL)
        let root = try XCTUnwrap(
            repository.modelContainer.mainContext.fetch(FetchDescriptor<PlayerStateEntity>()).first
        )
        root.schemaVersion = GameRepository.currentSchemaVersion + 1
        try repository.modelContainer.mainContext.save()

        XCTAssertThrowsError(try repository.load()) { error in
            XCTAssertEqual(
                error as? GamePersistenceError,
                .unsupportedSchemaVersion(
                    entity: "PlayerStateEntity",
                    found: GameRepository.currentSchemaVersion + 1
                )
            )
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: directory.appending(path: "CorruptStores").path
            )
        )
    }

    func testCorruptStoreAndSidecarsAreQuarantinedTogether() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "DeepMine.store")
        for url in StoreQuarantineCoordinator.storeFamilyURLs(for: storeURL) {
            try Data("corrupt".utf8).write(to: url)
        }

        let quarantined = try XCTUnwrap(
            StoreQuarantineCoordinator.quarantine(
                storeURL: storeURL,
                now: Date(timeIntervalSince1970: 1_750_000_000)
            )
        )

        XCTAssertEqual(quarantined.deletingLastPathComponent().lastPathComponent, "CorruptStores")
        XCTAssertEqual(
            Set(try FileManager.default.contentsOfDirectory(atPath: quarantined.path)),
            Set(["DeepMine.store", "DeepMine.store-wal", "DeepMine.store-shm"])
        )
        for url in StoreQuarantineCoordinator.storeFamilyURLs(for: storeURL) {
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        }
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "GamePersistenceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
