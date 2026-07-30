import DeepMineCore
import Foundation
import XCTest
@testable import DeepMineProbe

@MainActor
final class GameStoreProgressionTests: XCTestCase {
    func testPurchasePersistsCanonicalOreDebitAndLevel() throws {
        let fixture = makeFixture(player: PlayerState(resources: Resources(ore: 500)))

        let result = try fixture.store.purchaseEquipment(.drill, commandID: UUID())

        XCTAssertEqual(result, .purchased(equipment: .drill, newLevel: 2, cost: 100))
        XCTAssertEqual(fixture.repository.player.resources.ore, 400)
        XCTAssertEqual(fixture.repository.player.equipment.drill, 2)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 1)
    }

    func testInsufficientPurchaseDoesNotSaveOrMutatePlayer() throws {
        let player = PlayerState(resources: Resources(ore: 99))
        let fixture = makeFixture(player: player)

        let result = try fixture.store.purchaseEquipment(.drill, commandID: UUID())

        XCTAssertEqual(result, .insufficientOre(required: 100, available: 99))
        XCTAssertEqual(fixture.repository.player, player)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 0)
    }

    func testRepeatedCommandDoesNotSpendOreTwice() throws {
        let fixture = makeFixture(player: PlayerState(resources: Resources(ore: 500)))
        let commandID = UUID()

        _ = try fixture.store.purchaseEquipment(.drill, commandID: commandID)
        let replay = try fixture.store.purchaseEquipment(.drill, commandID: commandID)

        XCTAssertEqual(replay, .duplicate)
        XCTAssertEqual(fixture.repository.player.resources.ore, 400)
        XCTAssertEqual(fixture.repository.player.equipment.drill, 2)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 1)
    }

    func testMaximumLevelDoesNotSave() throws {
        let fixture = makeFixture(player: PlayerState(
            resources: Resources(ore: 10_000),
            equipment: EquipmentLevels(drill: Balance.maximumEquipmentLevel)
        ))

        XCTAssertEqual(try fixture.store.purchaseEquipment(.drill), .maximumLevel)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 0)
    }

    func testPurchasePropagatesStorageFailureWithoutMutatingRepository() throws {
        let player = PlayerState(resources: Resources(ore: 500))
        let fixture = makeFixture(player: player)
        fixture.repository.failPlayerSave = true

        XCTAssertThrowsError(try fixture.store.purchaseEquipment(.drill))
        XCTAssertEqual(fixture.repository.player, player)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 1)
    }

    func testWeeklyLedgerUsesInjectedReferenceClockAndWeekBoundary() throws {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        let sunday = date(2026, 7, 26, calendar: calendar, timeZone: timeZone)
        let monday = date(2026, 7, 27, calendar: calendar, timeZone: timeZone)
        let player = PlayerState(history: [
            historyEntry(at: sunday, minutes: 15, plan: .safe, depth: 80),
            historyEntry(at: monday, minutes: 50, plan: .survey, depth: 160, vein: .crystal)
        ])
        let fixture = makeFixture(
            player: player,
            date: date(2026, 7, 29, calendar: calendar, timeZone: timeZone),
            calendar: calendar,
            timeZone: timeZone
        )

        let ledger = try fixture.store.weeklyLedger()

        XCTAssertEqual(ledger.focusedMinutes, 50)
        XCTAssertEqual(ledger.totalSessions, 1)
        XCTAssertEqual(ledger.completedSessions, 1)
        XCTAssertEqual(ledger.deepestReturnMeters, 160)
        XCTAssertEqual(ledger.planMix.first { $0.plan == .survey }?.count, 1)
        XCTAssertEqual(ledger.veinHistory.map(\.vein), [.crystal])
    }

    func testRecommendationUsesSelectedPlanDurationAndGrade() throws {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        let now = date(2026, 7, 29, calendar: calendar, timeZone: timeZone)
        let player = PlayerState(
            resources: Resources(ore: 10_000),
            equipment: EquipmentLevels(drill: 3, cart: 2, lamp: 2),
            lifetimeFocusCredits: 12,
            streakDays: 7,
            lastSelectedPlan: .survey,
            lastSelectedDuration: .minutes50
        )
        let fixture = makeFixture(player: player, date: now, calendar: calendar, timeZone: timeZone)
        let expected = try UpgradeAdvisor.recommend(
            for: player,
            nextSession: RewardInput(
                completionID: UUID(uuidString: "44454550-4D49-4E45-0000-000000000140")!,
                outcome: .completed,
                sessionLength: .minutes50,
                plan: .survey,
                verificationGrade: .open,
                growthFocusCredits: 12,
                streakDays: 7,
                dailySessionNumber: 1,
                equipment: player.equipment,
                vein: nil,
                resonanceBoostActive: false,
                startingDailyMinutes: 0,
                permanentUpgrades: player.permanentUpgrades
            )
        )

        XCTAssertEqual(try fixture.store.recommendedUpgrade(verificationGrade: .open), expected)
    }

    private func makeFixture(
        player: PlayerState,
        date: Date = Date(timeIntervalSince1970: 1_800_000_000),
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> GameStoreFixture {
        let repository = FakeSessionRepository()
        repository.player = player
        let clock = FakeClock(wall: date)
        return GameStoreFixture(
            repository: repository,
            system: FakeSystemCoordinator(),
            clock: clock,
            store: GameStore(
                repository: repository,
                coordinator: FakeSystemCoordinator(),
                clock: clock,
                calendar: calendar,
                timeZone: timeZone
            )
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> Date {
        calendar.date(from: DateComponents(
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12
        ))!
    }

    private func historyEntry(
        at date: Date,
        minutes: Int,
        plan: MinePlan,
        depth: Int,
        vein: VeinKind? = nil
    ) -> SessionHistoryEntry {
        SessionHistoryEntry(
            completionID: UUID(),
            endedAt: date,
            focusedMinutes: minutes,
            focusCredits: Double(minutes) / Balance.minutesPerFocusCredit,
            plan: plan,
            verificationGrade: .sealed,
            oreEarned: Double(minutes) * 10,
            vein: vein,
            depthAfter: depth,
            completed: true
        )
    }
}
