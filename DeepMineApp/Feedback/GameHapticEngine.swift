import CoreHaptics
import Foundation
import UIKit

/// Plays the patterns from `GameHapticPattern`.
///
/// Uses CoreHaptics where the device supports it because the shapes carry meaning — a
/// heavy double thud for the shaft door reads differently from a bright sparkle for a
/// vein, and `UINotificationFeedbackGenerator` cannot express that difference. Falls back
/// to the UIKit generators when CoreHaptics is unavailable rather than going silent.
@MainActor
final class GameHapticEngine {
    private var engine: CHHapticEngine?
    private var startFailed = false

    func play(_ pattern: GameHapticPattern) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            playFallback(pattern)
            return
        }
        do {
            try playCoreHaptics(pattern)
        } catch {
            // A failure here is cosmetic. Degrade rather than surface it.
            playFallback(pattern)
        }
    }

    /// Warms the engine so the first event of a session is not delayed by start-up.
    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        _ = try? runningEngine()
    }

    private func playCoreHaptics(_ pattern: GameHapticPattern) throws {
        let engine = try runningEngine()
        let events = pattern.transients.map { time, intensity, sharpness in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: time
            )
        }
        let player = try engine.makePlayer(with: try CHHapticPattern(events: events, parameters: []))
        try player.start(atTime: CHHapticTimeImmediate)
    }

    private func runningEngine() throws -> CHHapticEngine {
        if let engine { return engine }
        guard !startFailed else { throw GameHapticError.unavailable }
        do {
            let created = try CHHapticEngine()
            // The engine stops when the app backgrounds; recreate lazily instead of
            // holding a dead reference.
            created.stoppedHandler = { [weak self] _ in
                Task { @MainActor in self?.engine = nil }
            }
            created.resetHandler = { [weak self] in
                Task { @MainActor in self?.engine = nil }
            }
            try created.start()
            engine = created
            return created
        } catch {
            startFailed = true
            throw error
        }
    }

    private func playFallback(_ pattern: GameHapticPattern) {
        if let notification = pattern.fallbackNotification {
            UINotificationFeedbackGenerator().notificationOccurred(notification)
            return
        }
        if let impact = pattern.fallbackImpact {
            UIImpactFeedbackGenerator(style: impact).impactOccurred()
        }
    }
}

enum GameHapticError: Error {
    case unavailable
}
