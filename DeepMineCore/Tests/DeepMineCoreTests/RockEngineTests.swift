import XCTest
@testable import DeepMineCore

final class RockEngineTests: XCTestCase {
    // MARK: Generation

    func testSegmentGenerationIsDeterministic() {
        let first = RockGenerator.segment(at: 137)
        let second = RockGenerator.segment(at: 137)
        XCTAssertEqual(first, second)
    }

    func testDistinctSegmentsDifferInWeakPointPlacement() {
        let points = (0..<80)
            .compactMap { RockGenerator.segment(at: $0).weakPoint }
            .map { [$0.unitX, $0.unitY] }
        XCTAssertGreaterThan(Set(points.map(\.description)).count, 1)
    }

    func testIntegrityGrowsWithDepth() {
        let shallow = RockGenerator.segment(at: 10).maximumIntegrity
        let deep = RockGenerator.segment(at: 200).maximumIntegrity
        XCTAssertGreaterThan(deep, shallow)
    }

    /// Integrity must outrun the damage a segment's own ore can buy — otherwise upgrades
    /// have nothing to fix — but only by a little, or the descent walls off (D-044).
    ///
    /// Comparing integrity against raw ore, as this once did, compares a resistance to a
    /// currency. What matters is resistance against the damage that currency purchases:
    /// ore compounds at 1.07 a segment and a level costs 1.34, so a segment funds
    /// log(1.07)/log(1.34) levels of 1.12 damage.
    func testIntegrityOutrunsThePurchasedDamageItFunds() {
        let levelsPerSegment = log(Balance.segmentOreGrowthRate)
            / log(Balance.equipmentPriceGrowthRate)
        let damageGrowth = pow(Balance.drillRewardGrowthRate, levelsPerSegment)
        let slowdown = Balance.segmentIntegrityGrowthRate / damageGrowth

        XCTAssertGreaterThan(slowdown, 1, "A descent that speeds up forever has no goal")
        // Above ~3% a segment the gap compounds into a wall: 1.057 was a factor of three
        // million across a 300-segment run, and the abyss became unreachable.
        XCTAssertLessThan(slowdown, 1.05, "The descent must slow, not stop")
    }

    func testSeamsLandOnTheInterval() {
        XCTAssertTrue(RockGenerator.segment(at: Balance.seamSegmentInterval).isSeam)
        XCTAssertTrue(RockGenerator.segment(at: Balance.seamSegmentInterval * 3).isSeam)
        XCTAssertFalse(RockGenerator.segment(at: Balance.seamSegmentInterval + 1).isSeam)
    }

    func testSegmentZeroIsNotASeam() {
        XCTAssertFalse(RockGenerator.segment(at: 0).isSeam)
    }

    func testSeamPaysMoreThanItsNeighbour() {
        let seam = RockGenerator.segment(at: Balance.seamSegmentInterval)
        let neighbour = RockGenerator.segment(at: Balance.seamSegmentInterval + 1)
        XCTAssertGreaterThan(seam.oreYield, neighbour.oreYield)
    }

    func testRegionFollowsDepth() {
        XCTAssertEqual(RockGenerator.segment(at: 0).region, .entry)
        let crystalIndex = ProgressionEngine.segmentIndex(forDepth: Balance.crystalRegionDepth)
        XCTAssertEqual(RockGenerator.segment(at: crystalIndex).region, .crystal)
        let abyssIndex = ProgressionEngine.segmentIndex(forDepth: Balance.abyssRegionDepth)
        XCTAssertEqual(RockGenerator.segment(at: abyssIndex).region, .abyss)
    }

    func testNegativeIndexClampsToFirstSegment() {
        XCTAssertEqual(RockGenerator.segment(at: -5), RockGenerator.segment(at: 0))
    }

    func testWeakPointStaysInsideTheFace() {
        for index in 0..<200 {
            guard let point = RockGenerator.segment(at: index).weakPoint else { continue }
            XCTAssertGreaterThanOrEqual(point.unitX, Balance.weakPointEdgeInset)
            XCTAssertLessThanOrEqual(point.unitX, 1 - Balance.weakPointEdgeInset)
            XCTAssertGreaterThanOrEqual(point.unitY, Balance.weakPointEdgeInset)
            XCTAssertLessThanOrEqual(point.unitY, 1 - Balance.weakPointEdgeInset)
        }
    }

    // MARK: Damage stages

    func testDamageStageSpansAllFourValues() {
        let segment = RockGenerator.segment(at: 5)
        let full = segment.maximumIntegrity
        XCTAssertEqual(segment.damageStage(remaining: full), 1)
        XCTAssertEqual(segment.damageStage(remaining: full * 0.5), 2)
        XCTAssertEqual(segment.damageStage(remaining: full * 0.2), 4)
        XCTAssertEqual(segment.damageStage(remaining: .zero), 4)
    }

    func testDamageStageClampsOutOfRangeIntegrity() {
        let segment = RockGenerator.segment(at: 5)
        XCTAssertEqual(segment.damageStage(remaining: segment.maximumIntegrity * 10), 1)
        XCTAssertEqual(segment.damageStage(remaining: BigNumber(-100)), 4)
    }

    // MARK: Resolution

    func testDamageBelowIntegrityLeavesSegmentIntact() {
        let segment = RockGenerator.segment(at: 0)
        let result = RockEngine.resolve(
            damage: BigNumber(1),
            segmentIndex: 0,
            remainingIntegrity: segment.maximumIntegrity
        )
        XCTAssertEqual(result.segmentsBroken, 0)
        XCTAssertEqual(result.segmentIndex, 0)
        XCTAssertTrue(result.oreGained.isZero)
        XCTAssertEqual(
            result.remainingIntegrity.doubleValue,
            segment.maximumIntegrity.doubleValue - 1,
            accuracy: 1e-9
        )
    }

    func testExactLethalDamageBreaksTheSegment() {
        let segment = RockGenerator.segment(at: 0)
        let result = RockEngine.resolve(
            damage: segment.maximumIntegrity,
            segmentIndex: 0,
            remainingIntegrity: segment.maximumIntegrity
        )
        XCTAssertEqual(result.segmentsBroken, 1)
        XCTAssertEqual(result.segmentIndex, 1)
        XCTAssertEqual(result.oreGained, segment.oreYield)
    }

    /// Without carry, a large offline haul would break one segment and discard the rest.
    func testOverflowCarriesAcrossManySegments() {
        let start = RockGenerator.segment(at: 0)
        let result = RockEngine.resolve(
            damage: BigNumber(10_000),
            segmentIndex: 0,
            remainingIntegrity: start.maximumIntegrity
        )
        XCTAssertGreaterThan(result.segmentsBroken, 5)
        XCTAssertEqual(result.segmentIndex, result.segmentsBroken)
        XCTAssertFalse(result.wasTruncated)
    }

    func testCarriedOreMatchesTheSegmentsActuallyBroken() {
        let start = RockGenerator.segment(at: 0)
        let result = RockEngine.resolve(
            damage: BigNumber(5_000),
            segmentIndex: 0,
            remainingIntegrity: start.maximumIntegrity
        )
        let expected = (0..<result.segmentsBroken)
            .reduce(BigNumber.zero) { $0 + RockGenerator.segment(at: $1).oreYield }
        XCTAssertEqual(result.oreGained.exponent, expected.exponent)
        XCTAssertEqual(result.oreGained.mantissa, expected.mantissa, accuracy: 1e-9)
    }

    func testResolutionReportsTruncationInsteadOfLoopingForever() {
        let start = RockGenerator.segment(at: 0)
        let result = RockEngine.resolve(
            damage: BigNumber(mantissa: 1, exponent: 200),
            segmentIndex: 0,
            remainingIntegrity: start.maximumIntegrity,
            maximumSegments: 32
        )
        XCTAssertTrue(result.wasTruncated)
        XCTAssertEqual(result.segmentsBroken, 32)
    }

    func testZeroAndNegativeDamageAreNoOps() {
        let segment = RockGenerator.segment(at: 3)
        for damage in [BigNumber.zero, BigNumber(-50)] {
            let result = RockEngine.resolve(
                damage: damage,
                segmentIndex: 3,
                remainingIntegrity: segment.maximumIntegrity
            )
            XCTAssertEqual(result.segmentsBroken, 0)
            XCTAssertEqual(result.remainingIntegrity, segment.maximumIntegrity)
            XCTAssertFalse(result.wasTruncated)
        }
    }

    func testSeamCountIsReported() {
        let start = RockGenerator.segment(at: 0)
        let result = RockEngine.resolve(
            damage: BigNumber(mantissa: 1, exponent: 12),
            segmentIndex: 0,
            remainingIntegrity: start.maximumIntegrity,
            maximumSegments: 60
        )
        let expected = (0..<result.segmentsBroken)
            .filter { RockGenerator.segment(at: $0).isSeam }
            .count
        XCTAssertEqual(result.seamsBroken, expected)
    }

    // MARK: Depth mapping

    func testSegmentDepthRoundTrips() {
        for index in [0, 1, 30, 300, 1_000] {
            let depth = ProgressionEngine.depthMeters(forSegmentIndex: index)
            XCTAssertEqual(ProgressionEngine.segmentIndex(forDepth: depth), index)
        }
    }
}
