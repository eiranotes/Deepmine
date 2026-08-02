import DeepMineCore
import Foundation
import SwiftData
import XCTest
@testable import DeepMine

@MainActor
final class GameStorePersistenceTests: XCTestCase {
    func testUnsupportedLifecycleSchemaFailsBeforeMutation() throws {
        let repository = try GameRepository.inMemory()
        let context = repository.modelContainer.mainContext
        context.insert(GameSessionEntity(schemaVersion: GameSchemaV1.version + 1))
        try context.save()
        XCTAssertThrowsError(try repository.load()) { error in
            XCTAssertEqual(
                error as? GamePersistenceError,
                .unsupportedSchemaVersion(
                    entity: "GameSessionEntity", found: GameSchemaV1.version + 1
                )
            )
        }
    }

    func testReturnReportCanBeConsumedWithoutDeletingPlayerState() throws {
        let repository = try GameRepository.inMemory()
        let report = GameReturnReport(
            sessionID: UUID(), completionID: UUID(), outcome: .completed,
            verificationGrade: .sealed, focusedMinutes: 25, oreEarned: 50,
            vein: nil, depthMeters: 10,
            completedAt: Date(timeIntervalSince1970: 1_800_000_000),
            clockAssessment: .valid, warnings: []
        )
        let session = PersistedGameSession(
            id: report.sessionID, completionID: report.completionID,
            originCommandID: nil, length: .minutes25, plan: .safe,
            startedAt: report.completedAt.addingTimeInterval(-1_500),
            endsAt: report.completedAt,
            clockAnchor: ClockAnchor(
                wallClock: report.completedAt.addingTimeInterval(-1_500),
                monotonicNanoseconds: 1
            ),
            randomSeed: 1, phase: .completed, systemsConfigured: true,
            abandonRequested: false, abandonSnapshot: nil,
            blockingEnabled: true, shieldMaintained: true,
            forcedShieldRemoval: false, forcedRemovalPending: false,
            openReason: nil, alarmDelivery: .none, liveActivityID: nil, warnings: []
        )
        let player = PlayerState(
            resources: Resources(ore: 321),
            equipment: EquipmentLevels(drill: 8, cart: 7, lamp: 6),
            rememberedEquipment: EquipmentLevels(drill: 18, cart: 17, lamp: 16),
            refinementTiers: RefinementTiers(drill: 1, cart: 2, lamp: 3),
            earnedAchievementIDs: ["first-rock", "deep-500"]
        )
        try repository.commitSession(player: player, report: report, cleanupSession: session)
        try repository.finishSessionCleanup(report: report)

        try repository.clearReturnReport()

        XCTAssertNil(try repository.loadReturnReport())
        XCTAssertNil(try repository.loadActiveSession())
        XCTAssertEqual(try repository.loadPlayer(), player)
    }
}
