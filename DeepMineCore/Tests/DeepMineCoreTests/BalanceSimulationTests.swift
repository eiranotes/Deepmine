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
            "persona,day,sessions,completed,abandoned,focused_minutes,ore_earned,ore_balance,current_depth,record_depth,drill,cart,lamp,prestige,fatigued_minutes"
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
    ///
    /// Measured on depth rather than on cumulative ore (D-070). Ore is an exponential
    /// function of depth — a segment at 2,000m pays astronomically more than one at 500m —
    /// so two players a few hundred metres apart show wallets orders of magnitude apart
    /// while playing the same game. The 1.5-20x ore band was written when sessions *were*
    /// the economy and every wallet was a linear function of focus; against a clicker
    /// curve it measures the exponent, not the access question it was asked to measure.
    func testFocusAmplifierIsWorthUsingButNotMandatory() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 30)

        // A player who never focuses must reach comparable depth. This is the property
        // the gate exists for: the game cannot be gated behind Screen Time permission.
        XCTAssertGreaterThan(result.heavyLightDepthGap, 0.5)
        XCTAssertLessThanOrEqual(result.heavyLightDepthGap, 2)

        // Focus still has to buy something, or the amplifier is decoration. It buys ore,
        // and no upper bound is asserted on it: ore compounds with depth by design.
        XCTAssertGreaterThan(result.heavyLightOreGap, 1.5)
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
        XCTAssertGreaterThanOrEqual(standard.finalRecordDepth, light.finalRecordDepth)
        XCTAssertGreaterThanOrEqual(heavy.finalRecordDepth, standard.finalRecordDepth)

        // Depth is a count of rock, so it can only ever be non-negative and finite.
        for summary in result.summaries {
            XCTAssertGreaterThanOrEqual(summary.finalCurrentDepth, 0)
            XCTAssertGreaterThanOrEqual(summary.finalRecordDepth, summary.finalCurrentDepth)
            XCTAssertLessThan(summary.finalRecordDepth, Int.max)
        }
    }

    func testEveryPersonaStillHasEquipmentLadderLeftAfterSixMonths() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 180)
        for summary in result.summaries {
            XCTAssertLessThan(
                summary.equipment.drill,
                Balance.equipmentLevelArithmeticBound,
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
