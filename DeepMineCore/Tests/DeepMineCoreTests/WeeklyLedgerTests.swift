import Foundation
import XCTest
@testable import DeepMineCore

final class WeeklyLedgerTests: XCTestCase {
    private let seoul = TimeZone(identifier: "Asia/Seoul")!
    private var calendar: Calendar {
        var value = Calendar(identifier: .iso8601)
        value.locale = Locale(identifier: "en_US_POSIX")
        value.firstWeekday = 2
        return value
    }

    func testEmptyWeekIsZeroSafeAndIncludesEveryPlan() {
        let reference = date(2026, 7, 29, 12)
        let ledger = WeeklyLedgerEngine.summarize(
            PlayerState(), referenceDate: reference, calendar: calendar, timeZone: seoul
        )

        XCTAssertEqual(ledger.focusedMinutes, 0)
        XCTAssertEqual(ledger.totalSessions, 0)
        XCTAssertEqual(ledger.completedSessions, 0)
        XCTAssertEqual(ledger.deepestReturnMeters, 0)
        XCTAssertEqual(ledger.oreEarned, 0)
        XCTAssertEqual(ledger.planMix.map(\.plan), MinePlan.allCases)
        XCTAssertTrue(ledger.planMix.allSatisfy { $0.count == 0 })
        XCTAssertTrue(ledger.entries.isEmpty)
        XCTAssertTrue(ledger.veinHistory.isEmpty)
    }

    func testWeeklyAggregationIncludesPartialReturnsAndSortsNewestFirst() {
        let older = history(
            id: 1, date: date(2026, 7, 27, 9), minutes: 25,
            plan: .safe, ore: 100, vein: nil, depth: 120, completed: true
        )
        let newer = history(
            id: 2, date: date(2026, 7, 29, 18), minutes: 8,
            plan: .survey, ore: 40, vein: .crystal, depth: 145, completed: false
        )
        let state = PlayerState(history: [older, newer])

        let ledger = WeeklyLedgerEngine.summarize(
            state,
            referenceDate: date(2026, 7, 30, 12),
            calendar: calendar,
            timeZone: seoul
        )

        XCTAssertEqual(ledger.focusedMinutes, 33)
        XCTAssertEqual(ledger.totalSessions, 2)
        XCTAssertEqual(ledger.completedSessions, 1)
        XCTAssertEqual(ledger.deepestReturnMeters, 145)
        XCTAssertEqual(ledger.oreEarned, 140)
        XCTAssertEqual(ledger.entries.map(\.completionID), [newer.completionID, older.completionID])
        XCTAssertEqual(ledger.veinHistory.map(\.vein), [.crystal])
        XCTAssertEqual(ledger.planMix.first { $0.plan == .safe }?.count, 1)
        XCTAssertEqual(ledger.planMix.first { $0.plan == .survey }?.count, 1)
        XCTAssertEqual(ledger.planMix.first { $0.plan == .deep }?.count, 0)
    }

    func testWeekBoundaryUsesInjectedTimeZone() {
        let sundayLateUTC = utcDate(2026, 7, 26, 16, 30)
        let priorLocalWeek = utcDate(2026, 7, 26, 14, 30)
        let state = PlayerState(history: [
            history(id: 1, date: sundayLateUTC, minutes: 25),
            history(id: 2, date: priorLocalWeek, minutes: 50)
        ])

        let ledger = WeeklyLedgerEngine.summarize(
            state,
            referenceDate: date(2026, 7, 27, 12),
            calendar: calendar,
            timeZone: seoul
        )

        XCTAssertEqual(ledger.totalSessions, 1)
        XCTAssertEqual(ledger.entries.first?.completionID, uuid(1))
        XCTAssertEqual(ledger.focusedMinutes, 25)
    }

    func testLedgerCodableRoundTrip() throws {
        let state = PlayerState(history: [history(id: 1, date: date(2026, 7, 29, 9))])
        let value = WeeklyLedgerEngine.summarize(
            state,
            referenceDate: date(2026, 7, 29, 12),
            calendar: calendar,
            timeZone: seoul
        )
        XCTAssertEqual(try JSONDecoder().decode(
            WeeklyLedger.self,
            from: JSONEncoder().encode(value)
        ), value)
    }

    private func history(
        id: UInt8,
        date: Date,
        minutes: Int = 25,
        plan: MinePlan = .safe,
        ore: Double = 100,
        vein: VeinKind? = nil,
        depth: Int = 120,
        completed: Bool = true
    ) -> SessionHistoryEntry {
        SessionHistoryEntry(
            completionID: uuid(id), endedAt: date,
            focusedMinutes: minutes, focusCredits: Double(minutes) / 25,
            plan: plan, verificationGrade: .sealed, oreEarned: ore,
            vein: vein, depthAfter: depth, completed: completed
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        var local = calendar
        local.timeZone = seoul
        return local.date(from: DateComponents(
            timeZone: seoul, year: year, month: month, day: day, hour: hour
        ))!
    }

    private func utcDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year, month: month, day: day, hour: hour, minute: minute
        ))!
    }

    private func uuid(_ suffix: UInt8) -> UUID {
        UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, suffix))
    }
}
