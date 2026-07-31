import AudioToolbox
import CoreHaptics
import Foundation
import UIKit

/// The moments worth answering with something the player can feel.
///
/// Only these exist: every one is a state change the player caused. Nothing fires during
/// a session, which is the one time the product promises silence.
enum GameFeedbackEvent: String, CaseIterable, Sendable {
    /// The shaft door closing. The most important moment in the concept.
    case sessionSealed
    /// Starting without blocking available.
    case sessionOpen
    case sessionCompleted
    case veinFound
    case upgradeInstalled
    case crewGrew
    case achievementEarned
    case sessionAbandoned
    case sessionCollapsed
    /// The clicker's core beats. Struck fires on every tap, so it must stay the lightest
    /// thing in this list — anything heavier becomes exhausting within a minute.
    case strike
    case criticalStrike
    case segmentBroken
    case seamBroken

    /// System sound used until authored SFX exist. Chosen for character, not realism:
    /// a heavier id for the door, a light tick for a purchase.
    var systemSoundID: SystemSoundID {
        switch self {
        case .sessionSealed: 1_113
        case .sessionOpen: 1_104
        case .sessionCompleted: 1_025
        case .veinFound: 1_027
        case .upgradeInstalled: 1_104
        case .crewGrew: 1_109
        case .achievementEarned: 1_025
        case .sessionAbandoned: 1_053
        case .sessionCollapsed: 1_073
        case .strike: 1_104
        case .criticalStrike: 1_027
        case .segmentBroken: 1_109
        case .seamBroken: 1_025
        }
    }

    var haptic: GameHapticPattern {
        switch self {
        case .sessionSealed: .doubleThud
        case .sessionOpen: .softTap
        case .sessionCompleted: .oreCascade
        case .veinFound: .sparkle
        case .upgradeInstalled: .crispTap
        case .crewGrew: .softTap
        case .achievementEarned: .risingTriple
        case .sessionAbandoned: .descendingPair
        case .sessionCollapsed: .harshBuzz
        case .strike: .featherTick
        case .criticalStrike: .crispTap
        case .segmentBroken: .doubleThud
        case .seamBroken: .oreCascade
        }
    }
}

/// Haptic shapes described independently of the engine, so the CoreHaptics path and the
/// UIKit fallback stay in agreement about what each event should feel like.
enum GameHapticPattern: Sendable {
    /// Lighter than `softTap`, because it fires on every single tap.
    case featherTick
    case softTap
    case crispTap
    case doubleThud
    case risingTriple
    case oreCascade
    case sparkle
    case descendingPair
    case harshBuzz

    /// (relativeTime, intensity, sharpness) transients.
    var transients: [(TimeInterval, Float, Float)] {
        switch self {
        case .featherTick: [(0, 0.22, 0.45)]
        case .softTap: [(0, 0.45, 0.3)]
        case .crispTap: [(0, 0.7, 0.85)]
        case .doubleThud: [(0, 1.0, 0.25), (0.13, 0.85, 0.2)]
        case .risingTriple: [(0, 0.5, 0.4), (0.09, 0.7, 0.6), (0.19, 1.0, 0.85)]
        case .oreCascade:
            [(0, 0.32, 0.72), (0.07, 0.46, 0.58), (0.14, 0.64, 0.4), (0.24, 1.0, 0.18)]
        case .sparkle: [(0, 0.35, 1.0), (0.06, 0.5, 1.0), (0.11, 0.4, 1.0), (0.17, 0.75, 1.0)]
        case .descendingPair: [(0, 0.8, 0.5), (0.14, 0.45, 0.25)]
        case .harshBuzz: [(0, 1.0, 1.0), (0.08, 1.0, 0.9), (0.16, 0.9, 0.8)]
        }
    }

    var fallbackNotification: UINotificationFeedbackGenerator.FeedbackType? {
        switch self {
        case .risingTriple, .oreCascade: .success
        case .descendingPair: .warning
        case .harshBuzz: .error
        default: nil
        }
    }

    var fallbackImpact: UIImpactFeedbackGenerator.FeedbackStyle? {
        switch self {
        case .featherTick: .light
        case .softTap: .light
        case .crispTap: .rigid
        case .doubleThud: .heavy
        case .sparkle: .soft
        default: nil
        }
    }
}
