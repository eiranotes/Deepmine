import Foundation
import XCTest
@testable import DeepMineCore

final class AchievementTests: XCTestCase {
    func testCatalogIDsAreUniqueAndThresholdsPositive() {
        let ids = AchievementCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate achievement id")
        XCTAssertTrue(AchievementCatalog.all.allSatisfy { $0.threshold > 0 })
        XCTAssertGreaterThanOrEqual(AchievementCatalog.all.count, 25)
    }

    /// D-028. A production reward would create a way to grow without focusing, so the
    /// reward type itself must make that impossible.
    func testNoAchievementCanPayProduction() {
        for definition in AchievementCatalog.all {
            switch definition.reward {
            case .crystals, .decoration, .theme, .badge:
                continue
            }
        }
        // Crystals are a cosmetic-unlock currency; cap the per-entry grant so the
        // catalog cannot quietly become an economy of its own.
        for definition in AchievementCatalog.all {
            if case let .crystals(quantity) = definition.reward {
                XCTAssertLessThanOrEqual(quantity, 8, definition.id)
                XCTAssertGreaterThan(quantity, 0, definition.id)
            }
        }
    }

    /// D-029. Every metric must be a monotonically accumulating quantity: nothing that
    /// can be measured per day or per hour, which is what would turn these into quests.
    func testEveryMetricIsCumulativeOrCurrentLevel() {
        let allowed: Set<AchievementMetric> = [
            .completedSessions, .lifetimeFocusMinutes, .depthMeters, .streakDays,
            .goalDaysEarned, .distinctVeinKinds, .veinDiscoveries, .drillLevel,
            .lowestEquipmentLevel, .sealedCompletions, .prestigeCount,
            .deepCompletions, .surveyCompletions
        ]
        XCTAssertEqual(Set(AchievementMetric.allCases), allowed)
        XCTAssertTrue(AchievementCatalog.all.allSatisfy { allowed.contains($0.metric) })
    }

    func testEvaluationIsIdempotentAndNeverPaysTwice() {
        var state = PlayerState(
            completedSessionCount: 1,
            history: [entry(completed: true)]
        )
        let first = AchievementEngine.evaluate(in: &state)
        XCTAssertTrue(first.contains { $0.definition.id == "first.return" })
        let crystalsAfterFirst = state.resources.crystals

        let second = AchievementEngine.evaluate(in: &state)
        XCTAssertTrue(second.isEmpty)
        XCTAssertEqual(state.resources.crystals, crystalsAfterFirst)
    }

    func testProgressReportsCurrentValueAndFractionForUnearned() {
        var state = PlayerState(lifetimeFocusCredits: 12)
        AchievementEngine.evaluate(in: &state)
        let progress = AchievementEngine.progress(for: state)
        guard let tenHours = progress.first(where: { $0.definition.id == "focus.10h" }) else {
            return XCTFail("focus.10h missing from catalog")
        }
        XCTAssertEqual(tenHours.current, 300)
        XCTAssertEqual(tenHours.fraction, 0.5, accuracy: 1e-9)
        XCTAssertEqual(tenHours.remaining, 300)
        XCTAssertFalse(tenHours.isEarned)
    }

    func testAlreadyOwnedCosmeticPaysNothingRatherThanConverting() {
        var state = PlayerState(
            history: (0..<5).map { entry(completed: true, vein: VeinKind.allCases[$0]) },
            unlockedThemes: [.entry, .crystal]
        )
        let grants = AchievementEngine.evaluate(in: &state)
        let all5 = grants.first { $0.definition.id == "vein.all5" }
        XCTAssertNotNil(all5)
        XCTAssertNil(all5?.appliedReward, "Owning the theme already must not pay a substitute")
        XCTAssertTrue(state.earnedAchievementIDs.contains("vein.all5"))
    }

    func testEarnedSetSurvivesRoundTripAndOlderSavesDecode() throws {
        var state = PlayerState(completedSessionCount: 1, history: [entry(completed: true)])
        AchievementEngine.evaluate(in: &state)
        let data = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(PlayerState.self, from: data)
        XCTAssertEqual(restored.earnedAchievementIDs, state.earnedAchievementIDs)

        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        json.removeValue(forKey: "earnedAchievementIDs")
        let legacy = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(PlayerState.self, from: legacy)
        XCTAssertTrue(decoded.earnedAchievementIDs.isEmpty)
    }

    func testPrestigeKeepsEarnedAchievements() {
        var state = PlayerState(
            runFocusCredits: Balance.initialPrestigeTarget,
            completedSessionCount: 1,
            history: [entry(completed: true)]
        )
        AchievementEngine.evaluate(in: &state)
        let earned = state.earnedAchievementIDs
        XCTAssertFalse(earned.isEmpty)
        PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)
        XCTAssertEqual(state.earnedAchievementIDs, earned)
    }

    private func entry(completed: Bool, vein: VeinKind? = nil) -> SessionHistoryEntry {
        SessionHistoryEntry(
            completionID: UUID(),
            endedAt: Date(timeIntervalSince1970: 0),
            focusedMinutes: 25,
            focusCredits: 1,
            plan: .safe,
            verificationGrade: .sealed,
            oreEarned: 100,
            vein: vein,
            depthAfter: 12,
            completed: completed
        )
    }
}
