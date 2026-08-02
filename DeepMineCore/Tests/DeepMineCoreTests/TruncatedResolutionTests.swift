import XCTest
@testable import DeepMineCore

/// A resolution walks at most `maximumSegmentsPerResolution` segments so one call cannot
/// loop unbounded. Until now the damage past that cap was dropped, which meant a long
/// offline haul paid the player for less rock than they actually broke.
final class TruncatedResolutionTests: XCTestCase {
    /// Enough damage to break far more than one resolution allows.
    private func hugeDamage() -> BigNumber {
        var total = BigNumber.zero
        for index in 0..<(Balance.maximumSegmentsPerResolution * 3) {
            total += RockGenerator.segment(at: index).maximumIntegrity
        }
        return total
    }

    private func lateGameState(atDepthMeters depthMeters: Int) -> PlayerState {
        let segmentIndex = depthMeters / Balance.metersPerSegment
        let equipmentLevel = Balance.maximumEquipmentLevel(forDepth: depthMeters)
        let refinementTier = RefinementEngine.unlockedTiers(forLevel: equipmentLevel)
        return PlayerState(
            equipment: EquipmentLevels(
                drill: equipmentLevel,
                cart: equipmentLevel,
                lamp: equipmentLevel
            ),
            refinementTiers: RefinementTiers(
                drill: refinementTier,
                cart: refinementTier,
                lamp: refinementTier
            ),
            mineFace: MineFaceState(segmentIndex: segmentIndex),
            deepestSegmentIndex: segmentIndex
        )
    }

    func testTruncationReportsTheDamageItCouldNotSpend() {
        let resolution = RockEngine.resolve(
            damage: hugeDamage(),
            segmentIndex: 0,
            remainingIntegrity: RockGenerator.segment(at: 0).maximumIntegrity
        )
        XCTAssertTrue(resolution.wasTruncated)
        XCTAssertEqual(resolution.segmentsBroken, Balance.maximumSegmentsPerResolution)
        XCTAssertGreaterThan(resolution.unspentDamage, .zero)
    }

    func testAnUntruncatedResolutionHasNothingLeftOver() {
        let segment = RockGenerator.segment(at: 0)
        let resolution = RockEngine.resolve(
            damage: segment.maximumIntegrity,
            segmentIndex: 0,
            remainingIntegrity: segment.maximumIntegrity
        )
        XCTAssertFalse(resolution.wasTruncated)
        XCTAssertEqual(resolution.unspentDamage, .zero)
    }

    /// The regression this fixes: the same total damage must break the same number of
    /// segments whether it arrives in one call or several.
    func testOneLargeTickBreaksAsMuchAsSeveralSmallOnes() {
        var equipment = EquipmentLevels(drill: 1, cart: 190, lamp: 1)
        var single = PlayerState()
        single.equipment = equipment
        var split = PlayerState()
        split.equipment = equipment

        let span: TimeInterval = 8 * 60 * 60
        MiningLoop.advance(seconds: span, in: &single)
        for _ in 0..<16 {
            MiningLoop.advance(seconds: span / 16, in: &split)
        }

        // Re-driving is not expected to be exact to the segment — the split run re-reads a
        // partially damaged face each time — but it must land in the same neighbourhood
        // rather than hundreds of segments short.
        let difference = abs(single.mineFace.segmentIndex - split.mineFace.segmentIndex)
        XCTAssertLessThanOrEqual(difference, 2, "single \(single.mineFace.segmentIndex), split \(split.mineFace.segmentIndex)")
        equipment = single.equipment
        XCTAssertGreaterThan(single.mineFace.segmentIndex, Balance.maximumSegmentsPerResolution)
    }

    func testCarriedDamageIsAppliedRatherThanDropped() {
        var carried = PlayerState()
        carried.equipment = EquipmentLevels(drill: 1, cart: 190, lamp: 1)
        let capped = carried

        MiningLoop.advance(seconds: 8 * 60 * 60, in: &carried)

        // Simulates the old behaviour: one resolution, remainder discarded.
        let power = MiningLoop.power(for: capped)
        let single = MineFaceEngine.advance(
            face: capped.mineFace,
            power: power,
            seconds: 8 * 60 * 60,
            equipment: capped.equipment,
            modifications: capped.equipmentModifications
        )

        XCTAssertTrue(single.wasTruncated)
        XCTAssertGreaterThan(carried.mineFace.segmentIndex, single.face.segmentIndex)
        XCTAssertGreaterThan(carried.resources.ore.doubleValue, single.oreGained.doubleValue)
    }

    /// Re-driving must terminate. Damage large enough to exceed every pass still returns.
    func testRedrivingIsBounded() {
        var state = PlayerState()
        state.equipment = EquipmentLevels(drill: 200, cart: 200, lamp: 1)
        let update = MiningLoop.advance(seconds: 8 * 60 * 60, in: &state)
        XCTAssertLessThanOrEqual(
            update.segmentsBroken,
            Balance.maximumSegmentsPerResolution
                * Balance.maximumResolutionPasses
                * Balance.maximumResolutionPasses
        )
    }

    /// The merged update has to report what the whole tick did, not just its first pass.
    func testTheReportedUpdateCoversEveryPass() {
        var state = PlayerState()
        state.equipment = EquipmentLevels(drill: 1, cart: 190, lamp: 1)
        let update = MiningLoop.advance(seconds: 8 * 60 * 60, in: &state)

        XCTAssertGreaterThan(update.segmentsBroken, Balance.maximumSegmentsPerResolution)
        XCTAssertEqual(update.face.segmentIndex, state.mineFace.segmentIndex)
        XCTAssertGreaterThan(update.oreGained, .zero)
    }

    func testEightHourSettlementConsumesAllDamageAt150Kilometres() {
        var state = lateGameState(atDepthMeters: 150_000)
        let creditedSeconds = Balance.maximumOfflineHours * 3_600
            * Balance.offlineEfficiency

        let update = MiningLoop.advance(seconds: creditedSeconds, in: &state)

        XCTAssertFalse(update.wasTruncated)
        XCTAssertEqual(update.unspentDamage, .zero)
        XCTAssertGreaterThan(
            update.segmentsBroken,
            Balance.maximumSegmentsPerResolution * Balance.maximumResolutionPasses
        )
    }

    func testEightHourSettlementConsumesAllDamageAt500Kilometres() {
        var state = lateGameState(atDepthMeters: 500_000)
        let creditedSeconds = Balance.maximumOfflineHours * 3_600
            * Balance.offlineEfficiency

        let update = MiningLoop.advance(seconds: creditedSeconds, in: &state)

        XCTAssertFalse(update.wasTruncated)
        XCTAssertEqual(update.unspentDamage, .zero)
        XCTAssertGreaterThan(
            update.segmentsBroken,
            Balance.maximumSegmentsPerResolution * Balance.maximumResolutionPasses
        )
    }
}
