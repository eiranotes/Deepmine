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
    private let haptic: @MainActor (VerificationGrade) -> Void
    private let sound: @MainActor () -> Void

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
        haptic: @escaping @MainActor (VerificationGrade) -> Void = { grade in
            UINotificationFeedbackGenerator().notificationOccurred(
                grade == .collapsed ? .warning : .success
            )
        },
        sound: @escaping @MainActor () -> Void = {
            AudioServicesPlaySystemSound(SystemSoundID(1104))
        }
    ) {
        self.defaults = defaults
        receiptKey = "deepmine.return.feedback.\(scope)"
        dismissedKey = "deepmine.return.dismissed.\(scope)"
        self.haptic = haptic
        self.sound = sound
    }

    @discardableResult
    func playRewardOnce(completionID: UUID, grade: VerificationGrade) -> Bool {
        guard claim(completionID, key: receiptKey) else { return false }
        if preference(Self.hapticPreferenceKey) { haptic(grade) }
        if preference(Self.soundPreferenceKey) { sound() }
        return true
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
