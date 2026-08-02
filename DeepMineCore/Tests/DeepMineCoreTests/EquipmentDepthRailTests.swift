import Foundation
import XCTest
@testable import DeepMineCore

final class EquipmentDepthRailTests: XCTestCase {
    func testRecordDepthKeepsTheEquipmentRailOpenAfterPrestige() {
        let recordSegment = ProgressionEngine.segmentIndex(forDepth: 600)
        var state = PlayerState(
            equipment: EquipmentLevels(drill: 20, cart: 20, lamp: 20),
            runSegmentsBroken: PrestigeEngine.target(prestigeIndex: 0),
            mineFace: MineFaceState(segmentIndex: recordSegment)
        )
        guard case .prestiged = PrestigeEngine.prestige(
            PrestigeCommand(id: UUID()), in: &state
        ) else {
            return XCTFail("Expected prestige")
        }
        XCTAssertEqual(state.depthMeters, 0)
        XCTAssertEqual(state.recordDepthMeters, 600)
        XCTAssertEqual(EquipmentEngine.unlockedMaximumLevel(in: state), 45)

        state.resources.ore = 1_000_000
        for expectedLevel in 2...6 {
            XCTAssertEqual(
                EquipmentEngine.purchase(
                    UpgradePurchaseCommand(id: UUID(), equipment: .drill),
                    in: &state
                ),
                .purchased(
                    equipment: .drill,
                    newLevel: expectedLevel,
                    cost: EquipmentEngine.upgradeCostBig(
                        for: .drill,
                        currentLevel: expectedLevel - 1,
                        rememberedLevel: 20
                    )!
                )
            )
        }
    }
}
