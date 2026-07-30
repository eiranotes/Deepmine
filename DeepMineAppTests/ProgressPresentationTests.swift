import DeepMineCore
import XCTest
@testable import DeepMineProbe

final class ProgressPresentationTests: XCTestCase {
    func testOverflowFixtureContainsFiveHundredActualWeeklyEntries() {
        let player = GameFixtures.progressOverflowPlayer
        let ledger = WeeklyLedgerEngine.summarize(
            player,
            referenceDate: GameFixtures.referenceDate,
            calendar: GameFixtures.progressCalendar,
            timeZone: GameFixtures.progressTimeZone
        )

        XCTAssertEqual(player.history.count, 500)
        XCTAssertEqual(ledger.totalSessions, 500)
        XCTAssertEqual(ledger.entries.count, 500)
        XCTAssertTrue(ledger.entries.allSatisfy { $0.endedAt <= GameFixtures.referenceDate })
    }

    func testProgressFixtureClockAndTimeZoneAreDeterministic() {
        let clock = DeterministicProgressClock(date: GameFixtures.referenceDate)

        XCTAssertEqual(clock.wallNow(), GameFixtures.referenceDate)
        XCTAssertEqual(GameFixtures.progressTimeZone.secondsFromGMT(), 0)
        XCTAssertEqual(GameFixtures.progressCalendar.identifier, .iso8601)
    }

    func testLargeOreValuesUseLocaleAppropriateCompactUnits() {
        let value = 9_876_543_210.0

        XCTAssertTrue(
            DeepMineNumberFormatter.string(value, locale: Locale(identifier: "ko_KR"))
                .contains(DeepMineStrings.text(.numberHundredMillion, locale: Locale(identifier: "ko_KR")))
        )
        XCTAssertTrue(
            DeepMineNumberFormatter.string(value, locale: Locale(identifier: "en_US"))
                .contains(DeepMineStrings.text(.numberBillion, locale: Locale(identifier: "en_US")))
        )
    }
}
