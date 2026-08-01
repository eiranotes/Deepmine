import DeepMineCore
import Foundation
import XCTest
@testable import DeepMine

final class DesignSystemContractTests: XCTestCase {
    func testPaletteContainsOnlyTheFourExactPigments() {
        XCTAssertEqual(DeepMinePalette.all.count, 4)
        XCTAssertEqual(
            Set(DeepMinePalette.all.map(\.hex)),
            Set(["#10100F", "#373630", "#E7E0CF", "#C58C39"])
        )
        XCTAssertEqual(DeepMinePalette.coal, DeepMinePigment(
            name: "coal", hex: "#10100F", red: 16, green: 16, blue: 15
        ))
        XCTAssertEqual(DeepMinePalette.shale, DeepMinePigment(
            name: "shale", hex: "#373630", red: 55, green: 54, blue: 48
        ))
        XCTAssertEqual(DeepMinePalette.limestone, DeepMinePigment(
            name: "limestone", hex: "#E7E0CF", red: 231, green: 224, blue: 207
        ))
        XCTAssertEqual(DeepMinePalette.brass, DeepMinePigment(
            name: "brass", hex: "#C58C39", red: 197, green: 140, blue: 57
        ))
    }

    func testEveryCatalogKeyResolvesInKoreanAndEnglish() {
        for localeID in ["ko", "en"] {
            let locale = Locale(identifier: localeID)
            for key in DeepMineStringKey.allCases {
                let value = DeepMineStrings.text(key, locale: locale)
                XCTAssertFalse(value.isEmpty, "Missing \(localeID) value for \(key.rawValue)")
                XCTAssertNotEqual(value, key.rawValue, "Unresolved \(localeID) key \(key.rawValue)")
            }
        }
        XCTAssertEqual(DeepMineStrings.text(.actionStart, locale: Locale(identifier: "ko")), "채굴 시작")
        XCTAssertEqual(DeepMineStrings.text(.actionStart, locale: Locale(identifier: "en")), "Start mining")
    }

    func testEveryStatusHasTextSymbolAndFourPigmentSemantics() {
        let palette = Set(DeepMinePalette.all.map(\.hex))
        for status in DeepMineStatus.allCases {
            XCTAssertFalse(status.symbol.isEmpty)
            XCTAssertTrue(palette.contains(status.pigment.hex))
            XCTAssertNotEqual(
                DeepMineStrings.text(status.titleKey, locale: Locale(identifier: "ko")),
                status.titleKey.rawValue
            )
        }
        XCTAssertTrue(DeepMineStatus.mining.isFilled)
        XCTAssertTrue(DeepMineStatus.failed.isFilled)
        XCTAssertFalse(DeepMineStatus.completed.isFilled)
        XCTAssertNotEqual(DeepMineStatus.attention.symbol, DeepMineStatus.failed.symbol)
    }

    func testFixtureFactoryIsDeterministicAndCoversEverySurface() throws {
        for scenario in GameFixtureScenario.allCases {
            XCTAssertEqual(GameFixtures.fixture(scenario), GameFixtures.fixture(scenario))
        }
        let surfaces = GameFixtures.allSurfaceFixtures
        XCTAssertEqual(surfaces.count, GameSurface.allCases.count)
        XCTAssertEqual(Set(surfaces.map(\.surface)), Set(GameSurface.allCases))
        XCTAssertTrue(surfaces.contains { $0.surface == .activityMinimal })
        XCTAssertNotNil(GameFixtures.fixture(.activeSealed).session)
        XCTAssertNotNil(GameFixtures.fixture(.completed).report)
        XCTAssertEqual(GameFixtures.fixture(.passiveVein).report?.vein, .crystal)
        XCTAssertEqual(GameFixtures.fixture(.collapsed).report?.oreEarned, 0)
        XCTAssertTrue(GameFixtures.fixture(.progressed).player.isDeepMiningUnlocked)

        let abandoned = GameFixtures.fixture(.abandoned)
        let report = try XCTUnwrap(abandoned.report)
        let length = try XCTUnwrap(report.length)
        let plan = try XCTUnwrap(report.plan)
        let input = RewardInput(
            completionID: report.completionID,
            outcome: report.outcome,
            sessionLength: length,
            plan: plan,
            verificationGrade: report.verificationGrade,
            growthFocusCredits: abandoned.player.lifetimeFocusCredits,
            streakDays: abandoned.player.streakDays,
            dailySessionNumber: 1,
            equipment: abandoned.player.equipment,
            vein: report.vein,
            resonanceBoostActive: abandoned.player.resonanceBoostPending,
            permanentUpgrades: abandoned.player.permanentUpgrades
        )
        XCTAssertEqual(
            report.oreEarned,
            try RewardCalculator.calculate(input).ore,
            accuracy: 0.000_001
        )
    }

    func testLocalizedNumberFormattingUsesPlayerScale() {
        let english = Locale(identifier: "en_US")
        let korean = Locale(identifier: "ko_KR")
        XCTAssertEqual(DeepMineNumberFormatter.string(999, locale: english), "999")
        XCTAssertEqual(DeepMineNumberFormatter.string(12_300, locale: english), "12.3K")
        XCTAssertEqual(DeepMineNumberFormatter.string(12_300, locale: korean), "1.2만")
        XCTAssertEqual(DeepMineNumberFormatter.string(.infinity, locale: korean), "—")
    }

    func testHitTargetsAndReducedMotionMappingAreExact() {
        XCTAssertGreaterThanOrEqual(DeepMineMetrics.minimumHitTarget, 44)
        XCTAssertGreaterThanOrEqual(DeepMineMetrics.buttonHeight, 44)
        XCTAssertGreaterThanOrEqual(DeepMineMetrics.toggleWidth, 44)
        XCTAssertEqual(Set(DeepMineMetalButtonRole.allCases).count, 4)
        XCTAssertEqual(
            DeepMineMotion.pressOffset(isPressed: true, reduceMotion: false),
            DeepMineMetrics.pressedTravel
        )
        XCTAssertEqual(DeepMineMotion.pressOffset(isPressed: true, reduceMotion: true), 0)
        XCTAssertEqual(DeepMineMotion.revealOffset(isRevealed: false, reduceMotion: true), 0)
        XCTAssertNil(DeepMineMotion.pressAnimation(reduceMotion: true))
        XCTAssertNotNil(DeepMineMotion.pressAnimation(reduceMotion: false))
    }

    /// The clicker pivot moved the sprite boundaries from 20/40 to 4/14 so an upgrade is
    /// seen within the first minutes of play. The art itself is still three tiers, so the
    /// contract this test guards is the clamp, not the old session-era thresholds.
    func testEquipmentArtTierBoundariesClampToShippedRange() {
        XCTAssertEqual(DeepMineArt.equipmentTier(level: -4), 1)
        XCTAssertEqual(DeepMineArt.equipmentTier(level: 1), 1)
        XCTAssertEqual(DeepMineArt.equipmentTier(level: 4), 1)
        XCTAssertEqual(DeepMineArt.equipmentTier(level: 5), 2)
        XCTAssertEqual(DeepMineArt.equipmentTier(level: 14), 2)
        XCTAssertEqual(DeepMineArt.equipmentTier(level: 15), 3)
        XCTAssertEqual(DeepMineArt.equipmentTier(level: Balance.maximumEquipmentLevel), 3)
        XCTAssertEqual(DeepMineArt.equipmentTier(level: 600), 3)
        XCTAssertEqual(
            DeepMineArt.equipment(.drill, level: 5),
            "Equipment_drill_tier2"
        )
    }
}
