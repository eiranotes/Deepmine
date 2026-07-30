import DeepMineCore
import XCTest
@testable import DeepMineProbe

@MainActor
final class RetentionSurfaceTests: XCTestCase {
    func testEveryAchievementResolvesATitleAndRewardInBothLanguages() {
        for definition in AchievementCatalog.all {
            let title = DeepMineAchievementLabels.title(for: definition)
            XCTAssertFalse(title.isEmpty, definition.id)
            XCTAssertFalse(title.contains("%"), "Unformatted specifier in \(definition.id)")
            let reward = DeepMineAchievementLabels.rewardText(definition.reward)
            XCTAssertFalse(reward.isEmpty, definition.id)
            XCTAssertFalse(reward.contains("%"), "Unformatted specifier in \(definition.id)")
        }
        for family in AchievementFamily.allCases {
            let key = DeepMineAchievementLabels.familyKey(family)
            for localeID in ["ko", "en"] {
                let value = DeepMineStrings.text(key, locale: Locale(identifier: localeID))
                XCTAssertNotEqual(value, key.rawValue, "Unresolved \(localeID) \(key.rawValue)")
            }
        }
    }

    /// Focus thresholds are stored in minutes and read in hours; a wrong scale would show
    /// "600 hours" for the ten hour badge.
    func testFocusAchievementTitlesReadInHours() {
        let tenHours = try? XCTUnwrap(AchievementCatalog.all.first { $0.id == "focus.10h" })
        guard let definition = tenHours else { return }
        XCTAssertTrue(
            DeepMineAchievementLabels.title(for: definition).contains("10"),
            "Expected hours, got \(DeepMineAchievementLabels.title(for: definition))"
        )
        let progress = AchievementProgress(definition: definition, current: 300, isEarned: false)
        XCTAssertEqual(DeepMineAchievementLabels.progressText(progress), "5 / 10")
    }

    func testSessionCompletionAwardsAchievementsIntoTheReport() async throws {
        let fixture = makeStore()
        try await fixture.store.start(length: .minutes25, plan: .safe)
        fixture.clock.advance(seconds: 25 * 60)
        let completed = try await fixture.store.completeIfNeeded()
        let report = try XCTUnwrap(completed)

        XCTAssertTrue(
            report.earnedAchievementIDs.contains("first.return"),
            "A first completed expedition must award its achievement"
        )
        let player = try fixture.store.playerState()
        XCTAssertTrue(player.earnedAchievementIDs.contains("first.return"))
    }

    func testAchievementsAreNotAwardedTwiceAcrossSessions() async throws {
        let fixture = makeStore()
        try await fixture.store.start(length: .minutes25, plan: .safe)
        fixture.clock.advance(seconds: 25 * 60)
        _ = try await fixture.store.completeIfNeeded()
        try await fixture.store.dismissReturnReport()

        try await fixture.store.start(length: .minutes25, plan: .safe)
        fixture.clock.advance(seconds: 25 * 60)
        let secondCompleted = try await fixture.store.completeIfNeeded()
        let second = try XCTUnwrap(secondCompleted)
        XCTAssertFalse(second.earnedAchievementIDs.contains("first.return"))
    }

    func testCrewNoticeOnlyAppearsWhenTheDrillCrossesAThreshold() {
        // Level 6 is the first crew step, level 7 is not.
        XCTAssertEqual(MineCrew.size(drillLevel: 5), 1)
        XCTAssertEqual(MineCrew.size(drillLevel: 6), 2)
        XCTAssertEqual(MineCrew.size(drillLevel: 7), 2)
        XCTAssertGreaterThan(
            MineCrew.size(drillLevel: 6),
            MineCrew.size(drillLevel: 5)
        )
        XCTAssertEqual(
            MineCrew.size(drillLevel: 7),
            MineCrew.size(drillLevel: 6),
            "A non-threshold purchase must not claim the crew grew"
        )
    }

    private struct Fixture {
        let store: GameStore
        let clock: FakeClock
        let repository: FakeSessionRepository
    }

    private func makeStore() -> Fixture {
        let repository = FakeSessionRepository()
        let clock = FakeClock()
        let store = GameStore(
            repository: repository,
            coordinator: FakeSystemCoordinator(),
            clock: clock,
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        return Fixture(store: store, clock: clock, repository: repository)
    }
}
