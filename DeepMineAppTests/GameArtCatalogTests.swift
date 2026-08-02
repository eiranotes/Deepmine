import Foundation
import SwiftUI
import XCTest
@testable import DeepMine

final class GameArtCatalogTests: XCTestCase {
    private var promptDocument: String {
        get throws {
            let root = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            return try String(
                contentsOf: root.appending(path: GameArtCatalog.promptDocumentPath),
                encoding: .utf8
            )
        }
    }

    private var shaftPromptDocument: String {
        get throws {
            let root = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            return try String(
                contentsOf: root.appending(path: GameArtCatalog.shaftPromptDocumentPath),
                encoding: .utf8
            )
        }
    }

    func testCatalogCoversTheFullPlannedSlotCount() {
        XCTAssertEqual(GameArtCatalog.allEntries.count, 24)
        XCTAssertEqual(GameArtCatalog.shaftEntries.count, 16)
    }

    func testSlotNamesAreUnique() {
        let names = GameArtCatalog.allEntries.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func testPromptIDsAreUnique() {
        let ids = GameArtCatalog.allEntries.map(\.promptID)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEverySlotHasAPromptInTheDocument() throws {
        let document = try promptDocument
        for entry in GameArtCatalog.allEntries {
            XCTAssertTrue(
                document.contains("`\(entry.promptID)`"),
                "\(GameArtCatalog.promptDocumentPath)에 프롬프트 ID `\(entry.promptID)`가 없다"
            )
            XCTAssertTrue(
                document.contains("`\(entry.name)`"),
                "\(GameArtCatalog.promptDocumentPath)에 자산 이름 `\(entry.name)`이 없다"
            )
        }
    }

    func testDocumentDeclaresNoPromptWithoutASlot() throws {
        let document = try promptDocument
        let known = Set(GameArtCatalog.allEntries.map(\.promptID))
        let pattern = try NSRegularExpression(
            pattern: "`(rockface-|fracture-|weakpoint-|debris-|resonance-)[a-z0-9-]+`"
        )
        let range = NSRange(document.startIndex..., in: document)

        for match in pattern.matches(in: document, range: range) {
            guard let matchRange = Range(match.range, in: document) else { continue }
            let identifier = document[matchRange]
                .trimmingCharacters(in: CharacterSet(charactersIn: "`"))
            XCTAssertTrue(
                known.contains(identifier),
                "문서의 `\(identifier)`에 대응하는 슬롯이 GameArtCatalog에 없다"
            )
        }
    }

    func testRockFaceCoversFourRegionsAndFourStages() {
        let faces = GameArtCatalog.allEntries.filter { $0.name.hasPrefix("RockFace_") }
        XCTAssertEqual(faces.count, 16)
        for region in ["entry", "crystal", "ruins", "abyss"] {
            for stage in 1...4 {
                XCTAssertTrue(faces.contains { $0.name == "RockFace_\(region)_stage\(stage)" })
            }
        }
    }

    func testUnknownRegionFallsBackToEntry() {
        XCTAssertEqual(
            GameArtCatalog.rockFace(region: "nonsense", stage: 2).name,
            "RockFace_entry_stage2"
        )
    }

    func testStageIsClampedToTheFourDrawnStages() {
        XCTAssertEqual(
            GameArtCatalog.rockFace(region: "entry", stage: 0).name,
            "RockFace_entry_stage1"
        )
        XCTAssertEqual(
            GameArtCatalog.rockFace(region: "entry", stage: 99).name,
            "RockFace_entry_stage4"
        )
    }

    func testEverySlotHasAPlaceholderAndResolvesWithoutTheAsset() {
        for entry in GameArtCatalog.installedEntries {
            XCTAssertNotNil(entry.placeholder)
            _ = GameArtView(entry: entry)
        }
    }

    func testEveryShaftSlotHasAPromptInItsDocument() throws {
        let document = try shaftPromptDocument
        for entry in GameArtCatalog.shaftEntries {
            XCTAssertTrue(
                document.contains("`\(entry.promptID)`"),
                "missing prompt \(entry.promptID)"
            )
            XCTAssertTrue(
                document.contains("`\(entry.name)`"),
                "missing asset name \(entry.name)"
            )
        }
    }

    func testAvailabilityDistinguishesInstalledFromAbsent() {
        GameArtAvailability.resetCache()
        XCTAssertTrue(GameArtAvailability.isInstalled("MinerSprite"))
        XCTAssertFalse(GameArtAvailability.isInstalled("NotAnAsset_\(UUID().uuidString)"))
    }

    func testEveryClickerSlotHasInstalledArt() {
        GameArtAvailability.resetCache()
        XCTAssertTrue(GameArtAvailability.missingEntries.isEmpty)
    }

    func testGeneratedProgressionMarksAreInstalled() {
        GameArtAvailability.resetCache()
        let names = [
            GameArtCatalog.refinementBadgeName(kind: "drill"),
            GameArtCatalog.refinementBadgeName(kind: "cart"),
            GameArtCatalog.refinementBadgeName(kind: "lamp"),
            GameArtCatalog.prestigeMemoryRingName
        ]
        for name in names {
            XCTAssertTrue(GameArtAvailability.isInstalled(name), "missing installed art \(name)")
        }
    }

    func testDeepGeologyChangesAtTheThreeLongRunThresholds() {
        XCTAssertEqual(
            GameArtCatalog.shaftRock(region: "abyss", depthMeters: 4_999).name,
            "ShaftRock_abyss"
        )
        XCTAssertEqual(
            GameArtCatalog.shaftRock(region: "abyss", depthMeters: 5_000).name,
            "ShaftRock_pressure"
        )
        XCTAssertEqual(
            GameArtCatalog.shaftRock(region: "abyss", depthMeters: 20_000).name,
            "ShaftRock_fault"
        )
        XCTAssertEqual(
            GameArtCatalog.shaftRock(region: "abyss", depthMeters: 100_000).name,
            "ShaftRock_core"
        )
    }
}
