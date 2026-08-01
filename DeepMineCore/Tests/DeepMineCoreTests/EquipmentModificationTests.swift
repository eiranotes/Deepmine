import XCTest
@testable import DeepMineCore

final class EquipmentModificationTests: XCTestCase {
    func testChoiceRequiresLevelAndIsMutuallyExclusive() {
        var locked = PlayerState(resources: Resources(ore: 10_000))
        XCTAssertEqual(
            EquipmentModificationEngine.purchase(
                EquipmentModificationCommand(id: UUID(), modification: .drillWide),
                in: &locked
            ),
            .levelLocked(requiredLevel: Balance.equipmentModificationUnlockLevel)
        )

        var state = PlayerState(
            resources: Resources(ore: 10_000),
            equipment: EquipmentLevels(drill: Balance.equipmentModificationUnlockLevel)
        )
        let result = EquipmentModificationEngine.purchase(
            EquipmentModificationCommand(id: UUID(), modification: .drillWide),
            in: &state
        )
        XCTAssertEqual(
            result,
            .purchased(modification: .drillWide, cost: Balance.drillModificationCost)
        )
        XCTAssertEqual(state.equipmentModifications.drill, .drillWide)
        XCTAssertEqual(
            EquipmentModificationEngine.purchase(
                EquipmentModificationCommand(id: UUID(), modification: .drillImpact),
                in: &state
            ),
            .alreadySelected(.drillWide)
        )
    }

    func testEveryBranchChangesItsPromisedRule() {
        let equipment = EquipmentLevels(drill: 8, cart: 8, lamp: 8)
        let base = StrikeEngine.power(
            equipment: equipment,
            permanent: PermanentUpgradeLevels()
        )
        let impact = StrikeEngine.power(
            equipment: equipment,
            permanent: PermanentUpgradeLevels(),
            modifications: EquipmentModifications(drill: .drillImpact)
        )
        let fleet = StrikeEngine.power(
            equipment: equipment,
            permanent: PermanentUpgradeLevels(),
            modifications: EquipmentModifications(cart: .cartFleet)
        )
        let freight = StrikeEngine.power(
            equipment: equipment,
            permanent: PermanentUpgradeLevels(),
            modifications: EquipmentModifications(cart: .cartFreight)
        )
        let fortune = StrikeEngine.power(
            equipment: equipment,
            permanent: PermanentUpgradeLevels(),
            modifications: EquipmentModifications(lamp: .lampFortune)
        )

        XCTAssertEqual(
            (impact.tapDamage / base.tapDamage).doubleValue,
            Balance.impactModificationDamageMultiplier,
            accuracy: 1e-9
        )
        XCTAssertEqual(
            (fleet.damagePerSecond / base.damagePerSecond).doubleValue,
            Balance.fleetModificationAutomationMultiplier,
            accuracy: 1e-9
        )
        XCTAssertEqual(freight.oreMultiplier, Balance.freightModificationOreMultiplier)
        XCTAssertEqual(
            fortune.criticalChance - base.criticalChance,
            Balance.fortuneModificationCriticalChance,
            accuracy: 1e-9
        )
        XCTAssertGreaterThan(
            EquipmentModificationEngine.boreWidth(
                drillLevel: 8,
                modifications: EquipmentModifications(drill: .drillWide)
            ),
            EquipmentModificationEngine.boreWidth(
                drillLevel: 8,
                modifications: .empty
            )
        )
    }

    func testBreakingRockCapturesTheVisibleEquipmentHistory() {
        var state = PlayerState(
            equipment: EquipmentLevels(drill: 12, cart: 18, lamp: 9),
            equipmentModifications: EquipmentModifications(drill: .drillWide)
        )

        MiningLoop.advance(seconds: 3_600, in: &state)

        let record = state.mineFace.boreHistory.last
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.drillLevel, 12)
        XCTAssertEqual(record?.cartLevel, 18)
        XCTAssertEqual(record?.lampLevel, 9)
        XCTAssertEqual(record?.drillModification, .drillWide)
    }

    func testPrestigeResetsRunChoiceAndPassage() {
        var state = PlayerState(
            resources: Resources(ore: 1_000),
            equipment: EquipmentLevels(drill: 8, cart: 8, lamp: 8),
            equipmentModifications: EquipmentModifications(drill: .drillImpact),
            runSegmentsBroken: PrestigeEngine.target(prestigeIndex: 0),
            mineFace: MineFaceState(
                segmentIndex: 20,
                boreHistory: [BoreRecord(
                    segmentIndex: 19,
                    drillLevel: 8,
                    cartLevel: 8,
                    lampLevel: 8
                )]
            )
        )

        _ = PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)

        XCTAssertEqual(state.equipmentModifications, .empty)
        XCTAssertTrue(state.mineFace.boreHistory.isEmpty)
    }

    func testOldFaceWithoutBoreHistoryStillDecodes() throws {
        let state = PlayerState(mineFace: MineFaceState(segmentIndex: 7))
        var json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(state)
        ) as! [String: Any]
        var face = json["mineFace"] as! [String: Any]
        face.removeValue(forKey: "boreHistory")
        json["mineFace"] = face
        json.removeValue(forKey: "equipmentModifications")

        let decoded = try JSONDecoder().decode(
            PlayerState.self,
            from: JSONSerialization.data(withJSONObject: json)
        )
        XCTAssertEqual(decoded.mineFace.segmentIndex, 7)
        XCTAssertTrue(decoded.mineFace.boreHistory.isEmpty)
        XCTAssertEqual(decoded.equipmentModifications, .empty)
    }
}
