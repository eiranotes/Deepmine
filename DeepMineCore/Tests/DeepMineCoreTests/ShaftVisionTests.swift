import XCTest
@testable import DeepMineCore

final class ShaftVisionTests: XCTestCase {
    func testColumnHasExactlyOneFaceAndOrdersDeepestLast() {
        var state = PlayerState(mineFace: MineFaceState(segmentIndex: 40))
        state.equipment.lamp = 1

        let layers = ShaftVision.layers(for: state)

        XCTAssertEqual(layers.filter { $0.position == .current }.count, 1)
        XCTAssertEqual(layers.first { $0.position == .current }?.segment.index, 40)
        XCTAssertEqual(layers.map(\.segment.index), layers.map(\.segment.index).sorted())
        XCTAssertTrue(layers.filter { $0.segment.index < 40 }.allSatisfy { $0.position == .broken })
        XCTAssertTrue(layers.filter { $0.segment.index > 40 }.allSatisfy { $0.position == .untouched })
    }

    func testTheSurfaceDoesNotShowRockAboveItself() {
        let state = PlayerState(mineFace: MineFaceState(segmentIndex: 0))
        let layers = ShaftVision.layers(for: state)

        XCTAssertEqual(layers.first?.segment.index, 0)
        XCTAssertTrue(layers.allSatisfy { $0.segment.index >= 0 })
        XCTAssertEqual(layers.first?.position, .current)
    }

    func testTheLampWidensTheViewAndStopsAtItsCeiling() {
        let dim = ShaftVision.visibleLayersBelow(lampLevel: Balance.minimumEquipmentLevel)
        let bright = ShaftVision.visibleLayersBelow(lampLevel: 30)
        let blinding = ShaftVision.visibleLayersBelow(lampLevel: Balance.maximumEquipmentLevel)

        XCTAssertGreaterThan(bright, dim)
        XCTAssertGreaterThan(blinding, bright)
        XCTAssertEqual(blinding, Int(Balance.maximumVisibleLayersBelow))

        var state = PlayerState(mineFace: MineFaceState(segmentIndex: 100))
        state.equipment.lamp = 1
        let narrow = ShaftVision.layers(for: state).count
        state.equipment.lamp = 30
        XCTAssertGreaterThan(ShaftVision.layers(for: state).count, narrow)
    }

    func testLightingFallsOffBelowTheFaceAndIsFullAboveIt() {
        var state = PlayerState(mineFace: MineFaceState(segmentIndex: 50))
        state.equipment.lamp = 20
        let layers = ShaftVision.layers(for: state)

        let above = layers.filter { $0.segment.index <= 50 }
        XCTAssertTrue(above.allSatisfy { $0.lighting == 1 })

        let below = layers.filter { $0.segment.index > 50 }
        XCTAssertEqual(below.map(\.lighting), below.map(\.lighting).sorted(by: >))
        XCTAssertTrue(below.allSatisfy { $0.lighting >= 0 && $0.lighting <= 1 })
    }

    func testRegionEntranceMarksOnlyTheFirstLayerOfARegion() {
        let firstCrystal = ProgressionEngine.segmentIndex(forDepth: Balance.crystalRegionDepth)
        var state = PlayerState(mineFace: MineFaceState(segmentIndex: firstCrystal))
        state.equipment.lamp = 1
        let layers = ShaftVision.layers(for: state)

        let entrances = layers.filter(\.isRegionEntrance).map(\.segment.index)
        XCTAssertEqual(entrances, [firstCrystal])
        XCTAssertEqual(
            layers.first { $0.segment.index == firstCrystal }?.segment.region,
            .crystal
        )
        XCTAssertEqual(
            layers.first { $0.segment.index == firstCrystal - 1 }?.segment.region,
            .entry
        )
    }
}
