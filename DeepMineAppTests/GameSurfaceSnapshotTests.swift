import Foundation
import XCTest
@testable import DeepMine

final class GameSurfaceSnapshotTests: XCTestCase {
    func testCodableRoundTripStaysBelowActivityPayloadLimit() throws {
        let snapshot = Self.makeSnapshot()

        let data = try JSONEncoder().encode(snapshot)

        XCTAssertLessThan(data.count, GameSurfaceSnapshotStore.maximumPayloadBytes)
        XCTAssertEqual(try JSONDecoder().decode(GameSurfaceSnapshot.self, from: data), snapshot)
        XCTAssertEqual(Set([snapshot]).count, 1)
    }

    func testLegacyRecommendationWithoutBigCostStillDecodes() throws {
        let snapshot = Self.makeSnapshot()
        var object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot))
                as? [String: Any]
        )
        var recommendation = try XCTUnwrap(
            object["upgradeRecommendation"] as? [String: Any]
        )
        recommendation.removeValue(forKey: "bigCost")
        object["upgradeRecommendation"] = recommendation

        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(GameSurfaceSnapshot.self, from: legacy)

        XCTAssertNil(decoded.upgradeRecommendation?.bigCost)
        XCTAssertEqual(decoded.upgradeRecommendation?.cost, 138)
    }

    func testStoreReadsMissingFreshAndStaleSnapshots() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        XCTAssertEqual(try fixture.store.read(at: Date(timeIntervalSince1970: 1_000)), .missing)

        let snapshot = Self.makeSnapshot(generatedAt: 1_000, staleAfter: 2_000)
        try fixture.writer.write(snapshot)

        XCTAssertEqual(
            try fixture.store.read(at: Date(timeIntervalSince1970: 1_999)),
            .fresh(snapshot)
        )
        XCTAssertEqual(
            try fixture.store.read(at: Date(timeIntervalSince1970: 2_000)),
            .stale(snapshot)
        )
    }

    func testWriterRejectsPayloadsAtOrAboveFourKilobytes() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let oversized = Self.makeSnapshot(sessionID: String(repeating: "x", count: 5_000))

        XCTAssertThrowsError(try fixture.writer.write(oversized)) { error in
            guard case let GameSurfaceSnapshotStoreError.payloadTooLarge(actual, limit) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertGreaterThanOrEqual(actual, limit)
            XCTAssertEqual(limit, 4_096)
        }
    }

    func testConcurrentReadersNeverObservePartialWrites() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let failures = ConcurrentFailureBox()

        DispatchQueue.concurrentPerform(iterations: 80) { index in
            do {
                if index.isMultiple(of: 2) {
                    try fixture.writer.write(Self.makeSnapshot(generatedAt: Double(1_000 + index)))
                } else {
                    _ = try fixture.store.read(at: Date(timeIntervalSince1970: 1_500))
                }
            } catch {
                failures.record(error)
            }
        }

        XCTAssertTrue(failures.errors.isEmpty)
        guard case .fresh = try fixture.store.read(at: Date(timeIntervalSince1970: 1_500)) else {
            return XCTFail("Expected a complete snapshot")
        }
    }

    func testGameArtRawIdentifiersUseSafeFallbacks() {
        XCTAssertEqual(GameArtName.miner(planID: "safe"), "MinerSprite")
        XCTAssertEqual(GameArtName.miner(planID: "deep"), "MinerPlan_deep")
        XCTAssertEqual(GameArtName.miner(planID: "survey"), "MinerPlan_survey")
        XCTAssertEqual(GameArtName.miner(planID: "unknown-sentinel"), "MinerSprite")

        XCTAssertEqual(GameArtName.region("crystal", prefix: "DIBanner"), "DIBanner_crystal")
        XCTAssertEqual(GameArtName.region("ruins", prefix: "StandBy"), "StandBy_ruins")
        XCTAssertEqual(GameArtName.region("unknown-sentinel", prefix: "StandBy"), "StandBy_entry")

        XCTAssertEqual(GameArtName.vein("abyss"), "Vein_abyss")
        XCTAssertEqual(GameArtName.vein("unknown-sentinel"), "VeinSprite")
        XCTAssertEqual(GameArtName.vein(nil), "VeinSprite")
    }

    private static func makeSnapshot(
        sessionID: String? = "session-1",
        generatedAt: TimeInterval = 1_000,
        staleAfter: TimeInterval = 2_000
    ) -> GameSurfaceSnapshot {
        GameSurfaceSnapshot(
            phase: .vein, sessionID: sessionID, outcomeID: "completed",
            planID: "survey", regionID: "ruins",
            depthMeters: 912, expectedOre: 320.5, earnedOre: 481.25, streakDays: 7,
            timerStartedAt: 900, timerEndsAt: 1_200, verificationGradeID: "sealed",
            veinID: "crystal",
            upgradeRecommendation: GameSurfaceUpgradeRecommendation(
                equipmentID: "drill", currentLevel: 2, nextLevel: 3,
                cost: 138, marginalExpectedOre: 24.5
            ),
            todayFocusedMinutes: 75, todayGoalMinutes: 100,
            generatedAt: generatedAt, staleAfter: staleAfter
        )
    }

    private func makeFixture() throws -> SnapshotFixture {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "GameSurfaceSnapshotTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = GameSurfaceSnapshotStore(directoryURL: directory)
        return SnapshotFixture(
            directory: directory,
            store: store,
            writer: GameSurfaceSnapshotWriter(store: store)
        )
    }
}

private struct SnapshotFixture: @unchecked Sendable {
    let directory: URL
    let store: GameSurfaceSnapshotStore
    let writer: GameSurfaceSnapshotWriter
    func remove() { try? FileManager.default.removeItem(at: directory) }
}

private final class ConcurrentFailureBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Error] = []
    var errors: [Error] { lock.withLock { storage } }
    func record(_ error: Error) { lock.withLock { storage.append(error) } }
}
