import DeepMineCore
import XCTest
@testable import DeepMineProbe

@MainActor
final class GameFeedbackPreferenceTests: XCTestCase {
    func testCompletedSessionFeelsLikeOreLoadingIntoACart() throws {
        let transients = GameFeedbackEvent.sessionCompleted.haptic.transients

        XCTAssertGreaterThanOrEqual(transients.count, 4)
        XCTAssertGreaterThan(try XCTUnwrap(transients.last).1, try XCTUnwrap(transients.first).1)
        XCTAssertGreaterThan(try XCTUnwrap(transients.last).0, try XCTUnwrap(transients.first).0)
        XCTAssertLessThan(try XCTUnwrap(transients.last).2, try XCTUnwrap(transients.first).2)
    }

    func testPreferencesDefaultOnAndPersistExplicitChanges() {
        let suite = "GameFeedbackPreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let feedback = GameFeedback(defaults: defaults)

        XCTAssertTrue(feedback.hapticsEnabled)
        XCTAssertTrue(feedback.soundEnabled)

        feedback.hapticsEnabled = false
        feedback.soundEnabled = false

        let reloaded = GameFeedback(defaults: defaults)
        XCTAssertFalse(reloaded.hapticsEnabled)
        XCTAssertFalse(reloaded.soundEnabled)
    }
}
