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

    func testCatalogCoversTheFullPlannedSlotCount() {
        XCTAssertEqual(GameArtCatalog.allEntries.count, 24)
    }

    func testSlotNamesAreUnique() {
        let names = GameArtCatalog.allEntries.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func testPromptIDsAreUnique() {
        let ids = GameArtCatalog.allEntries.map(\.promptID)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// The document is the only place the generation prompts live. If a slot exists in
    /// code with no prompt behind it, the art can never actually be made — and nothing
    /// else would catch that.
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

    /// And the reverse: a prompt written for a slot the code never asks for produces art
    /// that ships as dead weight.
    func testDocumentDeclaresNoPromptWithoutASlot() throws {
        let document = try promptDocument
        let known = Set(GameArtCatalog.allEntries.map(\.promptID))
        let pattern = try NSRegularExpression(pattern: "`(rockface-|fracture-|weakpoint-|debris-|resonance-)[a-z0-9-]+`")
        let range = NSRange(document.startIndex..., in: document)

        for match in pattern.matches(in: document, range: range) {
            guard let matchRange = Range(match.range, in: document) else { continue }
            let identifier = document[matchRange].trimmingCharacters(in: CharacterSet(charactersIn: "`"))
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
        XCTAssertEqual(GameArtCatalog.rockFace(region: "entry", stage: 0).name, "RockFace_entry_stage1")
        XCTAssertEqual(GameArtCatalog.rockFace(region: "entry", stage: 99).name, "RockFace_entry_stage4")
    }

    /// Placeholders exist precisely so an absent asset is not a crash. Asking for a slot
    /// that nobody has drawn must still yield something renderable.
    func testEverySlotHasAPlaceholderAndResolvesWithoutTheAsset() {
        for entry in GameArtCatalog.allEntries {
            XCTAssertNotNil(entry.placeholder)
            _ = GameArtView(entry: entry)
        }
    }

    /// The swap hinges entirely on this predicate telling the truth in both directions.
    /// `MinerSprite` is a real shipped asset and the random name cannot exist, so this
    /// fails if availability ever answers unconditionally.
    func testAvailabilityDistinguishesInstalledFromAbsent() {
        GameArtAvailability.resetCache()
        XCTAssertTrue(GameArtAvailability.isInstalled("MinerSprite"))
        XCTAssertFalse(GameArtAvailability.isInstalled("NotAnAsset_\(UUID().uuidString)"))
    }

    /// Until the 24 images are generated, every clicker slot is expected to be missing.
    /// When that stops being true this test should be updated, not deleted — it is the
    /// record of how much art still stands between here and a finished rock face.
    func testEveryClickerSlotIsStillAwaitingArt() {
        GameArtAvailability.resetCache()
        XCTAssertEqual(GameArtAvailability.missingEntries.count, GameArtCatalog.allEntries.count)
    }
}
