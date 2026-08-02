import XCTest
@testable import DeepMineCore

final class ShaftVisionTests: XCTestCase {
    func testHeadMovesContinuouslyThroughCurrentSegment() {
        let face = MineFaceState(
            segmentIndex: 40,
            remainingIntegrity: RockGenerator.segment(at: 40).maximumIntegrity * 0.25
        )
        let scene = ShaftSceneEngine.scene(for: PlayerState(mineFace: face))

        XCTAssertEqual(scene.faceDepthMeters, 160)
        XCTAssertEqual(scene.headDepthMeters, 163, accuracy: 0.001)
        XCTAssertEqual(
            scene.y(forDepthMeters: scene.headDepthMeters)
                - scene.y(forDepthMeters: scene.faceDepthMeters),
            3 * Balance.shaftPointsPerMeter,
            accuracy: 0.001
        )
    }

    func testSurfaceViewportNeverStartsAboveGround() {
        let scene = ShaftSceneEngine.scene(for: PlayerState())

        XCTAssertEqual(scene.topDepthMeters, 0)
        XCTAssertGreaterThan(scene.bottomDepthMeters, scene.headDepthMeters)
    }

    func testLampAndReachModificationOpenTheFutureRock() {
        let dim = ShaftSceneEngine.visibleMetersBelow(lampLevel: 1)
        let bright = ShaftSceneEngine.visibleMetersBelow(lampLevel: 30)
        let reach = ShaftSceneEngine.visibleMetersBelow(
            lampLevel: 1,
            modifications: EquipmentModifications(lamp: .lampReach)
        )

        XCTAssertGreaterThan(bright, dim)
        XCTAssertGreaterThan(reach, dim)
        XCTAssertEqual(
            ShaftSceneEngine.visibleMetersBelow(lampLevel: Balance.equipmentLevelArithmeticBound),
            Balance.maximumVisibleMetersBelow
        )
    }

    func testStrataSplitAtRegionBoundaryNotEverySegment() {
        let firstCrystal = ProgressionEngine.segmentIndex(forDepth: Balance.crystalRegionDepth)
        let scene = ShaftSceneEngine.scene(for: PlayerState(
            mineFace: MineFaceState(segmentIndex: firstCrystal)
        ))

        XCTAssertEqual(scene.strata.map(\.region), [.entry, .crystal])
        XCTAssertEqual(scene.strata.last?.startDepthMeters, Double(Balance.crystalRegionDepth))
        XCTAssertTrue(scene.strata.last?.isRegionEntrance == true)
    }

    func testBoreHistoryPreservesTheWidthUsedWhenRockBroke() {
        let narrow = BoreRecord(segmentIndex: 10, drillLevel: 1, cartLevel: 1, lampLevel: 1)
        let wide = BoreRecord(
            segmentIndex: 11,
            drillLevel: 8,
            cartLevel: 3,
            lampLevel: 4,
            drillModification: .drillWide
        )
        let state = PlayerState(mineFace: MineFaceState(
            segmentIndex: 12,
            boreHistory: [narrow, wide]
        ))
        let records = ShaftSceneEngine.scene(for: state).boreHistory

        XCTAssertEqual(records.map(\.segmentIndex), [10, 11])
        XCTAssertGreaterThan(records[1].boreWidthPoints, records[0].boreWidthPoints)
    }

    func testLightingFallsOffBelowTheHead() {
        let scene = ShaftSceneEngine.scene(for: PlayerState(
            mineFace: MineFaceState(segmentIndex: 50)
        ))

        XCTAssertEqual(scene.lighting(atDepthMeters: scene.headDepthMeters), 1)
        XCTAssertGreaterThan(
            scene.lighting(atDepthMeters: scene.headDepthMeters + 1),
            scene.lighting(atDepthMeters: scene.bottomDepthMeters)
        )
    }
}
