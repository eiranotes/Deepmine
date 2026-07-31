@preconcurrency import FamilyControls
import XCTest
@testable import DeepMine

@MainActor
final class ScreenTimeSelectionStorageTests: XCTestCase {
    func testFailedDraftSaveLeavesPublishedAndPersistedSelectionUnchanged() {
        let original = FamilyActivitySelection(includeEntireCategory: false)
        let replacement = FamilyActivitySelection(includeEntireCategory: true)
        let storage = FakeSelectionStorage(value: original, failsSave: true)
        let probe = ScreenTimeProbe(storage: storage)

        XCTAssertThrowsError(try probe.replaceSelection(replacement))
        XCTAssertEqual(probe.selection, original)
        XCTAssertEqual(storage.value, original)
        XCTAssertEqual(storage.saveAttempts, 1)
    }

    func testSuccessfulDraftSaveUpdatesStorageBeforePublishedSelection() throws {
        let original = FamilyActivitySelection(includeEntireCategory: false)
        let replacement = FamilyActivitySelection(includeEntireCategory: true)
        let storage = FakeSelectionStorage(value: original)
        let probe = ScreenTimeProbe(storage: storage)

        try probe.replaceSelection(replacement)

        XCTAssertEqual(storage.value, replacement)
        XCTAssertEqual(probe.selection, replacement)
        XCTAssertEqual(storage.saveAttempts, 1)
    }
}

@MainActor
private final class FakeSelectionStorage: ScreenTimeSelectionStoring {
    var value: FamilyActivitySelection
    var failsSave: Bool
    var saveAttempts = 0

    init(value: FamilyActivitySelection, failsSave: Bool = false) {
        self.value = value
        self.failsSave = failsSave
    }

    func load() throws -> FamilyActivitySelection { value }

    func save(_ selection: FamilyActivitySelection) throws {
        saveAttempts += 1
        if failsSave { throw FakeSelectionError.failed }
        value = selection
    }
}

private enum FakeSelectionError: Error { case failed }
