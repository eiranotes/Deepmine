import AudioToolbox
import DeepMineCore
import Foundation
import UIKit

@MainActor
final class GameFeedback {
    static let hapticPreferenceKey = "deepmine.preferences.haptics"
    static let soundPreferenceKey = "deepmine.preferences.returnSound"

    private let defaults: UserDefaults
    private let receiptKey: String
    private let dismissedKey: String
    private let hapticPlayer: @MainActor (GameHapticPattern) -> Void
    private let soundPlayer: @MainActor (SystemSoundID) -> Void

    var hapticsEnabled: Bool {
        get { preference(Self.hapticPreferenceKey) }
        set { persist(newValue, forKey: Self.hapticPreferenceKey) }
    }

    var soundEnabled: Bool {
        get { preference(Self.soundPreferenceKey) }
        set { persist(newValue, forKey: Self.soundPreferenceKey) }
    }

    init(
        defaults: UserDefaults = .standard,
        scope: String = "product",
        hapticPlayer: (@MainActor (GameHapticPattern) -> Void)? = nil,
        soundPlayer: @escaping @MainActor (SystemSoundID) -> Void = {
            AudioServicesPlaySystemSound($0)
        }
    ) {
        self.defaults = defaults
        receiptKey = "deepmine.return.feedback.\(scope)"
        dismissedKey = "deepmine.return.dismissed.\(scope)"
        if let hapticPlayer {
            self.hapticPlayer = hapticPlayer
        } else {
            let engine = GameHapticEngine()
            self.hapticPlayer = { engine.play($0) }
        }
        self.soundPlayer = soundPlayer
    }

    /// Fires for any player-caused state change. Cheap enough to call from a view action.
    func play(_ event: GameFeedbackEvent) {
        if preference(Self.hapticPreferenceKey) { hapticPlayer(event.haptic) }
        if preference(Self.soundPreferenceKey) { soundPlayer(event.systemSoundID) }
    }

    /// The return reward is receipt-guarded so relaunching onto a stored report does not
    /// replay the celebration. Other events are transient and need no receipt.
    @discardableResult
    func playRewardOnce(completionID: UUID, grade: VerificationGrade) -> Bool {
        guard claim(completionID, key: receiptKey) else { return false }
        play(event(for: grade))
        return true
    }

    private func event(for grade: VerificationGrade) -> GameFeedbackEvent {
        grade == .collapsed ? .sessionCollapsed : .sessionCompleted
    }

    func markDismissed(completionID: UUID) {
        _ = claim(completionID, key: dismissedKey)
    }

    func isDismissed(completionID: UUID) -> Bool {
        receipts(for: dismissedKey).contains(completionID.uuidString)
    }

    func resetUITestReceipts() {
        defaults.removeObject(forKey: receiptKey)
        defaults.removeObject(forKey: dismissedKey)
    }

    func configureUITestPreferences(haptics: Bool?, sound: Bool?) {
        if let haptics { hapticsEnabled = haptics }
        if let sound { soundEnabled = sound }
    }

    private func preference(_ key: String) -> Bool {
        defaults.object(forKey: key) == nil || defaults.bool(forKey: key)
    }

    private func persist(_ enabled: Bool, forKey key: String) {
        defaults.set(enabled, forKey: key)
        defaults.synchronize()
    }

    private func claim(_ id: UUID, key: String) -> Bool {
        var values = receipts(for: key)
        guard values.insert(id.uuidString).inserted else { return false }
        defaults.set(Array(values).sorted(), forKey: key)
        return true
    }

    private func receipts(for key: String) -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }
}
