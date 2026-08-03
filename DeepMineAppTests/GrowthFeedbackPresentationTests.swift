import DeepMineCore
import Foundation
import XCTest
@testable import DeepMine

final class GrowthFeedbackPresentationTests: XCTestCase {
    func testRateFormatterDoesNotCollapseTinyBigNumberToZero() {
        let value = BigNumber(mantissa: 1.25, exponent: -400)

        XCTAssertEqual(
            DeepMineRateFormatter.string(value, locale: Locale(identifier: "en_US")),
            "1.25e-400"
        )
    }

    func testFirstCartCallsOutManualToAutomationWithoutFakePercentage() throws {
        let before = PlayerState(
            equipment: EquipmentLevels(cart: 1),
            onboardingStage: .complete,
            mineFace: MineFaceState(segmentIndex: 10)
        )
        let after = PlayerState(
            equipment: EquipmentLevels(cart: 2),
            onboardingStage: .complete,
            mineFace: MineFaceState(segmentIndex: 10)
        )

        let impact = try XCTUnwrap(PurchaseImpact(
            before: before,
            after: after,
            equipment: .cart
        ))
        let presentation = PurchaseImpactPresentation(
            impact,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(presentation.label, "Ore/sec")
        XCTAssertEqual(presentation.beforeValue, "Manual mining")
        XCTAssertEqual(presentation.changeValue, "Automation started")
        XCTAssertFalse(presentation.transition.contains("0 →"))
        XCTAssertFalse(presentation.changeValue.contains("%"))
    }

    func testLocalizedImpactPresentationIncludesBeforeAfterAndPercentage() throws {
        let before = PlayerState(
            equipment: EquipmentLevels(drill: 1),
            onboardingStage: .complete,
            mineFace: MineFaceState(segmentIndex: 10)
        )
        let after = PlayerState(
            equipment: EquipmentLevels(drill: 2),
            onboardingStage: .complete,
            mineFace: MineFaceState(segmentIndex: 10)
        )

        let impact = try XCTUnwrap(PurchaseImpact(
            before: before,
            after: after,
            equipment: .drill
        ))
        let korean = PurchaseImpactPresentation(
            impact,
            locale: Locale(identifier: "ko_KR")
        )

        XCTAssertEqual(korean.label, "탭 출력")
        XCTAssertTrue(korean.transition.contains("→"))
        XCTAssertTrue(korean.changeValue.hasPrefix("+"))
        XCTAssertTrue(korean.changeValue.hasSuffix("%"))
    }

    func testRigUpgradeNamesTheSamePhysicalChangesAsTheWebContract() {
        func player(_ level: Int) -> PlayerState {
            PlayerState(
                equipment: EquipmentLevels(drill: level),
                onboardingStage: .complete
            )
        }

        XCTAssertEqual(
            RigUpgradePhysicalPresentation(
                equipment: .drill,
                before: player(1),
                after: player(2)
            ).detail,
            "D2 · T1→T2 본체 교체 · 정비 셀 1/4"
        )
        XCTAssertEqual(
            RigUpgradePhysicalPresentation(
                equipment: .drill,
                before: player(2),
                after: player(3)
            ).detail,
            "D3 · 정비 셀 1→2/4 증설"
        )
        XCTAssertEqual(
            RigUpgradePhysicalPresentation(
                equipment: .drill,
                before: player(4),
                after: player(5)
            ).detail,
            "D5 · G1 · 2형 하우징 교체"
        )
    }
}
