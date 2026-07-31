import XCTest
import DeepMineCore
@testable import DeepMineBalanceCLI

final class BalanceSimulationTests: XCTestCase {
    func testSimulationIsDeterministic() throws {
        XCTAssertEqual(
            try BalanceSimulator.run(seed: 260_729, days: 30),
            try BalanceSimulator.run(seed: 260_729, days: 30)
        )
    }

    func testCSVHeaderAndThirtyDayRowCount() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 30)
        let lines = result.csv.split(separator: "\n")
        XCTAssertEqual(
            lines.first,
            "persona,day,sessions,completed,abandoned,focused_minutes,ore_earned,ore_balance,depth,drill,cart,lamp,prestige,fatigued_minutes"
        )
        XCTAssertEqual(lines.count, 1 + PersonaID.allCases.count * 30)
    }

    /// Persona shape, not economy tuning. The focus-time gap falls out of how the
    /// personas are defined, so it survives any rebalancing of the clicker.
    ///
    /// Dropped with the pivot: first upgrade landing on session 1-2 (upgrades are bought
    /// with idle ore now, so "session" is the wrong unit), first prestige on day 7-10
    /// (pacing is being retuned), and heavy fatigue being zero (fatigue was deleted in
    /// D-034, so that assertion could no longer fail). See docs/BALANCE_GUARDRAILS.md.
    func testPersonaShapeHoldsAcrossRebalancing() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 30)
        XCTAssertLessThanOrEqual(result.heavyLightFocusGap, 10)
        XCTAssertEqual(BalanceSimulator.personas.map(\.dailyGoalMinutes), [25, 100, 100, 50])
    }

    /// The amplifier must be worth using and must not be mandatory. Those are the two
    /// failure modes the pivot named, and this is the gate between them.
    ///
    /// Before the pivot this measured 61.9x, because focus was the entire economy and a
    /// player who did not focus earned almost nothing. Now idle production is the
    /// baseline and does not care how disciplined anyone is, so heavy and light players
    /// converge on purpose. A gap near 1 would mean focus buys nothing; a large gap would
    /// mean the game is still gated behind Screen Time permission.
    func testFocusAmplifierIsWorthUsingButNotMandatory() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 30)
        XCTAssertGreaterThan(result.heavyLightOreGap, 1.5)
        XCTAssertLessThanOrEqual(result.heavyLightOreGap, 20)
    }

    /// Depth must never invert against play. This is the property that run-scoped depth
    /// once broke: a schedule that prestiged repeatedly read shallower than one that
    /// never did, despite far more play behind it.
    ///
    /// Retargeted for D-040. Depth now comes from broken rock, so the ordering is stated
    /// in terms of what actually moves a player down rather than in terms of focus
    /// credits. The old `depthExponent 1.15` bound is gone with it — depth is linear in
    /// segments now, so there is no exponent to bound.
    func testDepthNeverInvertsAgainstPlayAcrossPrestige() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 180)
        let light = try XCTUnwrap(result.summaries.first { $0.persona == .light })
        let standard = try XCTUnwrap(result.summaries.first { $0.persona == .standard })
        let heavy = try XCTUnwrap(result.summaries.first { $0.persona == .heavy })

        // Prestige must be survivable: the player who reset still ends up deeper.
        XCTAssertGreaterThan(standard.prestigeIndex, 0)
        XCTAssertGreaterThanOrEqual(standard.finalDepth, light.finalDepth)
        XCTAssertGreaterThanOrEqual(heavy.finalDepth, standard.finalDepth)

        // Depth is a count of rock, so it can only ever be non-negative and finite.
        for summary in result.summaries {
            XCTAssertGreaterThanOrEqual(summary.finalDepth, 0)
            XCTAssertLessThan(summary.finalDepth, Int.max)
        }
    }

    func testEveryPersonaStillHasEquipmentLadderLeftAfterSixMonths() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 180)
        for summary in result.summaries {
            XCTAssertLessThan(
                summary.equipment.drill,
                Balance.maximumEquipmentLevel,
                "\(summary.persona) exhausted the drill ladder within 180 days"
            )
        }
    }

    func testEqualTimeComparisonUsesOneHundredFiftyMinutesEach() throws {
        let rows = try BalanceSimulator.run(seed: 260_729, days: 30).equalTime
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows.map(\.minutes), [150, 150, 150])
        XCTAssertEqual(rows.map(\.sessions), [10, 6, 3])
        XCTAssertTrue(rows.allSatisfy { $0.ore.isFinite && $0.ore > 0 })
    }
}
