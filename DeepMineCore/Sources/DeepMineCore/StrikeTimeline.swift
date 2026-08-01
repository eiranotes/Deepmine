import Foundation

/// Which swing is being played. The variant changes weight and timing, never the amount of
/// damage — that stays a function of equipment, so a heavy swing is a reading of the same
/// hit rather than a second economy (D-058).
public enum StrikeVariant: String, CaseIterable, Sendable {
    case quick
    case heavy
    case critical
}

/// The single timeline a strike runs on. Pose, contact effects, sound and the damage itself
/// all read their moment from here, which is what keeps the tool from landing while the
/// body is somewhere else (D-055).
public struct StrikeTimeline: Equatable, Sendable {
    public let duration: TimeInterval
    public let contact: TimeInterval

    public init(duration: TimeInterval, contact: TimeInterval) {
        self.duration = duration
        self.contact = contact
    }

    public static func timeline(
        for variant: StrikeVariant,
        reduceMotion: Bool = false
    ) -> StrikeTimeline {
        guard !reduceMotion else {
            return StrikeTimeline(
                duration: Balance.reducedStrikeDuration,
                contact: Balance.reducedStrikeContact
            )
        }
        return switch variant {
        case .quick:
            StrikeTimeline(
                duration: Balance.quickStrikeDuration,
                contact: Balance.quickStrikeContact
            )
        case .heavy:
            StrikeTimeline(
                duration: Balance.heavyStrikeDuration,
                contact: Balance.heavyStrikeContact
            )
        case .critical:
            StrikeTimeline(
                duration: Balance.criticalStrikeDuration,
                contact: Balance.criticalStrikeContact
            )
        }
    }

    /// When each swing is allowed to start, and which variant it plays.
    ///
    /// Automation advances the rock on a short simulation step, but a swing is 560ms of
    /// animation: triggering the actor on every step restarts it before it can finish, so
    /// the miner freezes on the anticipation frame while the rock keeps losing integrity.
    /// The damage step and the visible swing are therefore separate clocks (D-058).
    public enum Cadence {
        /// A tap owns the actor briefly so an automatic swing cannot overwrite the pose
        /// mid-stroke. Damage from those overlapped steps is not lost — it lands on the
        /// rock as usual and is read at the next visible contact.
        public static func manualOwnsActor(
            now: TimeInterval,
            lastManualStrikeAt: TimeInterval?
        ) -> Bool {
            guard let lastManualStrikeAt else { return false }
            return now - lastManualStrikeAt < Balance.manualStrikeActorGuard
        }

        /// Whether an automatic swing may begin. Keeps the idle mine visibly working at a
        /// readable period instead of at the simulation step.
        public static func shouldStartAutomaticSwing(
            now: TimeInterval,
            lastSwingAt: TimeInterval?,
            lastManualStrikeAt: TimeInterval?
        ) -> Bool {
            guard !manualOwnsActor(now: now, lastManualStrikeAt: lastManualStrikeAt) else {
                return false
            }
            guard let lastSwingAt else { return true }
            return now - lastSwingAt >= Balance.automaticStrikeInterval
        }

        /// Alternating weight. A critical is always the heaviest read; everything else
        /// alternates so consecutive swings do not land identically.
        public static func variant(sequence: Int, wasCritical: Bool) -> StrikeVariant {
            if wasCritical { return .critical }
            return sequence.isMultiple(of: 2) ? .quick : .heavy
        }
    }

    /// Which of the four `MinerMiningStrip` frames is showing at `elapsed`.
    ///
    /// Anticipation runs up to contact, the contact frame is held briefly so the hit is
    /// legible, and recoil covers the rest. Outside the swing the actor is at ready.
    public func frameIndex(at elapsed: TimeInterval, frameCount: Int = 4) -> Int {
        guard frameCount > 1 else { return 0 }
        guard elapsed > 0, elapsed < duration else { return 0 }
        let contactHold = min(duration - contact, contact * 0.42)
        if elapsed < contact * 0.55 { return 1 }
        if elapsed < contact + contactHold { return 2 }
        return min(frameCount - 1, 3)
    }
}
