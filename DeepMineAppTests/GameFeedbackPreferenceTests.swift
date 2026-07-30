import DeepMineCore
import XCTest
@testable import DeepMineProbe

@MainActor
final class GameFeedbackPreferenceTests: XCTestCase {
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
