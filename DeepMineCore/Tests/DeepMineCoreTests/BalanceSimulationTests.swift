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

    func testPersonaTargetsWithoutSoftCap() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 30)
        let light = try XCTUnwrap(result.summaries.first { $0.persona == .light })
        let standard = try XCTUnwrap(result.summaries.first { $0.persona == .standard })
        let heavy = try XCTUnwrap(result.summaries.first { $0.persona == .heavy })

        XCTAssertTrue(result.summaries.allSatisfy {
            guard let session = $0.firstUpgradeSession else { return false }
            return (1...2).contains(session)
        })
        XCTAssertTrue((7...10).contains(try XCTUnwrap(standard.firstPrestigeDay)))
        XCTAssertLessThanOrEqual(result.heavyLightFocusGap, 10)
        XCTAssertEqual(BalanceSimulator.personas.map(\.dailyGoalMinutes), [25, 100, 100, 50])
        XCTAssertNil(light.firstPrestigeDay)
        // The fatigue soft cap is gone (D-034), so a heavy schedule is no longer
        // penalised for long days.
        XCTAssertEqual(heavy.fatiguedMinutes, 0)
    }

    func testBoundedGrowthKeepsGrossOreGapWithinObservedGuardrail() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 30)
        // Compounding equipment widens the ore gap on purpose: a 10x focus gap buys
        // more levels, and each level is worth a constant +12%. There is no
        // leaderboard or shared economy, so the guardrail exists to catch runaway
        // growth, not to equalise personas. Play-amount metrics stay at 10x below.
        XCTAssertGreaterThan(result.heavyLightOreGap, 10)
        XCTAssertLessThanOrEqual(result.heavyLightOreGap, 80)
        // Rose from 60.29 when the daily soft cap stopped discounting heavy days.
        XCTAssertEqual(result.heavyLightOreGap, 61.581264, accuracy: 0.000001)
    }

    func testDepthNeverInvertsAgainstFocusAcrossPrestige() throws {
        let result = try BalanceSimulator.run(seed: 260_729, days: 180)
        let light = try XCTUnwrap(result.summaries.first { $0.persona == .light })
        let standard = try XCTUnwrap(result.summaries.first { $0.persona == .standard })
        let heavy = try XCTUnwrap(result.summaries.first { $0.persona == .heavy })

        // Depth is the identity number, and it is what run-scoped depth inverted: a
        // standard schedule that prestiged repeatedly used to read shallower than a
        // light one that never did, despite four times the focus.
        XCTAssertGreaterThan(standard.prestigeIndex, 0)
        XCTAssertGreaterThan(standard.lifetimeFocusCredits, light.lifetimeFocusCredits)
        XCTAssertGreaterThan(standard.finalDepth, light.finalDepth)
        XCTAssertGreaterThan(heavy.finalDepth, standard.finalDepth)
        // Equal focus reads equal depth apart from abyss vein bonuses.
        let irregular = try XCTUnwrap(result.summaries.first { $0.persona == .irregular })
        XCTAssertEqual(irregular.lifetimeFocusCredits, light.lifetimeFocusCredits, accuracy: 1e-9)
        XCTAssertEqual(
            Double(irregular.finalDepth),
            Double(light.finalDepth),
            accuracy: Double(3 * Balance.abyssBonusDepthMeters)
        )
        // depthExponent 1.15 on a 10x focus gap is 10^1.15, plus abyss vein bonuses.
        XCTAssertLessThanOrEqual(Double(heavy.finalDepth) / Double(light.finalDepth), 16)
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
