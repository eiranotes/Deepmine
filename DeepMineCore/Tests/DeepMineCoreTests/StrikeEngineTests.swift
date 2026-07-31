import XCTest
@testable import DeepMineCore

final class StrikeEngineTests: XCTestCase {
    private func power(drill: Int = 1, cart: Int = 1, lamp: Int = 1) -> StrikePower {
        StrikeEngine.power(
            equipment: EquipmentLevels(drill: drill, cart: cart, lamp: lamp),
            permanent: PermanentUpgradeLevels()
        )
    }

    // MARK: Power

    func testBaseLoadoutHasNoAutomation() {
        let base = power()
        XCTAssertFalse(base.isAutomated)
        XCTAssertTrue(base.damagePerSecond.isZero)
    }

    /// The first cart upgrade is the moment the mine runs without the player. It has to
    /// be the purchase that turns automation on, not something granted at the start.
    func testFirstCartUpgradeStartsAutomation() {
        XCTAssertTrue(power(cart: 2).isAutomated)
    }

    func testTapDamageCompoundsWithDrill() {
        let low = power(drill: 5).tapDamage
        let high = power(drill: 25).tapDamage
        let ratio = (high / low).doubleValue
        let expected = pow(Balance.drillRewardGrowthRate, 20)
        XCTAssertEqual(ratio, expected, accuracy: expected * 1e-6)
    }

    func testAutomationCompoundsFasterThanLinear() {
        let ten = power(cart: 10).damagePerSecond.doubleValue
        let twenty = power(cart: 20).damagePerSecond.doubleValue
        XCTAssertGreaterThan(twenty / ten, 2)
    }

    func testLampRaisesCriticalChanceAndMultiplier() {
        XCTAssertGreaterThan(power(lamp: 30).criticalChance, power(lamp: 1).criticalChance)
        XCTAssertGreaterThan(power(lamp: 30).criticalMultiplier, power(lamp: 1).criticalMultiplier)
    }

    func testCriticalChanceIsCapped() {
        let extreme = power(lamp: 10_000)
        XCTAssertEqual(extreme.criticalChance, Balance.maximumCriticalChance)
    }

    func testPrestigeMultiplierScalesBothSources() {
        let plain = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 5, cart: 5, lamp: 1),
            permanent: PermanentUpgradeLevels()
        )
        let boosted = StrikeEngine.power(
            equipment: EquipmentLevels(drill: 5, cart: 5, lamp: 1),
            permanent: PermanentUpgradeLevels(),
            prestigeMultiplier: 4
        )
        XCTAssertEqual((boosted.tapDamage / plain.tapDamage).doubleValue, 4, accuracy: 1e-6)
        XCTAssertEqual(
            (boosted.damagePerSecond / plain.damagePerSecond).doubleValue,
            4,
            accuracy: 1e-6
        )
    }

    func testInvalidPrestigeMultiplierIsIgnored() {
        for bad in [0.0, -3.0, Double.nan, Double.infinity] {
            let result = StrikeEngine.power(
                equipment: EquipmentLevels(drill: 3),
                permanent: PermanentUpgradeLevels(),
                prestigeMultiplier: bad
            )
            XCTAssertEqual(result.tapDamage, power(drill: 3).tapDamage)
        }
    }

    // MARK: Impact meter

    func testImpactStartsEmptyAndClampsAtBothEnds() {
        XCTAssertEqual(ImpactMeter.empty.value, 0)
        XCTAssertEqual(ImpactMeter(value: -50).value, 0)
        XCTAssertEqual(ImpactMeter(value: 9_999).value, Balance.impactMeterMaximum)
    }

    func testImpactFillsWithTapsAndDecaysWithTime() {
        var meter = ImpactMeter.empty
        for _ in 0..<5 { meter = meter.registeringTap() }
        XCTAssertEqual(meter.value, Balance.impactPerTap * 5, accuracy: 1e-9)

        let decayed = meter.decayed(by: 2)
        XCTAssertEqual(
            decayed.value,
            meter.value - Balance.impactDecayPerSecond * 2,
            accuracy: 1e-9
        )
    }

    func testImpactDecayCannotGoNegative() {
        XCTAssertEqual(ImpactMeter(value: 5).decayed(by: 100).value, 0)
    }

    func testImpactDecayIgnoresNonPositiveSpan() {
        let meter = ImpactMeter(value: 40)
        XCTAssertEqual(meter.decayed(by: 0), meter)
        XCTAssertEqual(meter.decayed(by: -10), meter)
    }

    func testFullImpactMultiplierMatchesBalance() {
        let full = ImpactMeter(value: Balance.impactMeterMaximum)
        XCTAssertTrue(full.isFull)
        XCTAssertEqual(full.damageMultiplier, Balance.impactFullDamageMultiplier, accuracy: 1e-9)
        XCTAssertEqual(ImpactMeter.empty.damageMultiplier, 1, accuracy: 1e-9)
    }

    // MARK: Tap

    func testTapAppliesImpactMultiplier() {
        var generator = SeededGenerator(seed: 1)
        let loadout = power(drill: 10)
        let full = ImpactMeter(value: Balance.impactMeterMaximum)

        var quiet = SeededGenerator(seed: 1)
        let cold = StrikeEngine.tap(
            power: loadout,
            impact: .empty,
            hitWeakPoint: false,
            weakPointMultiplier: 1,
            using: &quiet
        )
        let hot = StrikeEngine.tap(
            power: loadout,
            impact: full,
            hitWeakPoint: false,
            weakPointMultiplier: 1,
            using: &generator
        )
        XCTAssertGreaterThan(hot.damage, cold.damage)
    }

    func testTapRaisesTheImpactMeter() {
        var generator = SeededGenerator(seed: 7)
        let outcome = StrikeEngine.tap(
            power: power(),
            impact: .empty,
            hitWeakPoint: false,
            weakPointMultiplier: 1,
            using: &generator
        )
        XCTAssertEqual(outcome.impact.value, Balance.impactPerTap, accuracy: 1e-9)
    }

    func testWeakPointMultipliesDamage() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        let loadout = power(drill: 8)
        let plain = StrikeEngine.tap(
            power: loadout, impact: .empty, hitWeakPoint: false,
            weakPointMultiplier: 3, using: &a
        )
        let onPoint = StrikeEngine.tap(
            power: loadout, impact: .empty, hitWeakPoint: true,
            weakPointMultiplier: 3, using: &b
        )
        XCTAssertEqual((onPoint.damage / plain.damage).doubleValue, 3, accuracy: 1e-6)
        XCTAssertTrue(onPoint.hitWeakPoint)
    }

    func testWeakPointMultiplierBelowOneCannotReduceDamage() {
        var a = SeededGenerator(seed: 5)
        var b = SeededGenerator(seed: 5)
        let loadout = power(drill: 4)
        let plain = StrikeEngine.tap(
            power: loadout, impact: .empty, hitWeakPoint: false,
            weakPointMultiplier: 0.1, using: &a
        )
        let onPoint = StrikeEngine.tap(
            power: loadout, impact: .empty, hitWeakPoint: true,
            weakPointMultiplier: 0.1, using: &b
        )
        XCTAssertEqual(onPoint.damage, plain.damage)
    }

    func testCriticalRateApproachesConfiguredChance() {
        var generator = SeededGenerator(seed: 2_024)
        let loadout = power(lamp: 20)
        var crits = 0
        let trials = 20_000
        for _ in 0..<trials {
            let outcome = StrikeEngine.tap(
                power: loadout, impact: .empty, hitWeakPoint: false,
                weakPointMultiplier: 1, using: &generator
            )
            if outcome.wasCritical { crits += 1 }
        }
        let observed = Double(crits) / Double(trials)
        XCTAssertEqual(observed, loadout.criticalChance, accuracy: 0.02)
    }

    func testTapIsDeterministicForTheSameSeed() {
        var a = SeededGenerator(seed: 99)
        var b = SeededGenerator(seed: 99)
        let loadout = power(drill: 6, lamp: 6)
        for _ in 0..<50 {
            let left = StrikeEngine.tap(
                power: loadout, impact: .empty, hitWeakPoint: false,
                weakPointMultiplier: 1, using: &a
            )
            let right = StrikeEngine.tap(
                power: loadout, impact: .empty, hitWeakPoint: false,
                weakPointMultiplier: 1, using: &b
            )
            XCTAssertEqual(left, right)
        }
    }

    // MARK: Automation

    func testAutomationDamageScalesWithElapsedTime() {
        let loadout = power(cart: 12)
        let short = StrikeEngine.automationDamage(power: loadout, seconds: 1)
        let long = StrikeEngine.automationDamage(power: loadout, seconds: 60)
        XCTAssertEqual((long / short).doubleValue, 60, accuracy: 1e-6)
    }

    func testAutomationYieldsNothingWithoutACart() {
        XCTAssertTrue(StrikeEngine.automationDamage(power: power(), seconds: 3_600).isZero)
    }

    func testAutomationRejectsNonPositiveOrInvalidSpans() {
        let loadout = power(cart: 10)
        for span in [0, -5, Double.nan, Double.infinity] as [TimeInterval] {
            XCTAssertTrue(StrikeEngine.automationDamage(power: loadout, seconds: span).isZero)
        }
    }

    /// Eight hours of automation must arrive as one amount that breaks many segments,
    /// which is the offline-return promise the whole idle loop rests on.
    func testEightHoursOfAutomationBreaksManySegments() {
        let loadout = power(cart: 15)
        let damage = StrikeEngine.automationDamage(power: loadout, seconds: 8 * 3_600)
        let result = RockEngine.resolve(
            damage: damage,
            segmentIndex: 0,
            remainingIntegrity: RockGenerator.segment(at: 0).maximumIntegrity
        )
        XCTAssertGreaterThan(result.segmentsBroken, 10)
        XCTAssertFalse(result.oreGained.isZero)
    }
}
