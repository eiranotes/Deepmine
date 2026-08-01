import Foundation

/// Where a resonance node is in its cycle.
///
/// Not to be confused with `VeinKind.resonance`, which is a session payout the mine hands
/// to the player. A node is the opposite kind of event: it appears, it is only worth
/// something if the player presses it, and missing it costs nothing but pays nothing
/// (D-057). An idle game needs at least one reason to look at the screen on purpose.
public enum ResonanceNodePhase: String, Codable, Equatable, Sendable {
    /// Counting down to the next appearance.
    case waiting
    /// On screen and claimable.
    case active
    /// Claimed; the boost is running.
    case claimed
    /// The window closed untouched. No reward, no penalty.
    case missed
}

public struct ResonanceNodeState: Codable, Equatable, Sendable {
    public private(set) var phase: ResonanceNodePhase
    /// How many windows have opened. Drives alternating placement so consecutive nodes do
    /// not appear in the same spot.
    public private(set) var cycle: Int
    public private(set) var appearsAt: Date?
    public private(set) var activeUntil: Date?
    public private(set) var boostUntil: Date?
    public private(set) var settlesAt: Date?

    public init(
        phase: ResonanceNodePhase = .waiting,
        cycle: Int = 0,
        appearsAt: Date? = nil,
        activeUntil: Date? = nil,
        boostUntil: Date? = nil,
        settlesAt: Date? = nil
    ) {
        self.phase = phase
        self.cycle = cycle
        self.appearsAt = appearsAt
        self.activeUntil = activeUntil
        self.boostUntil = boostUntil
        self.settlesAt = settlesAt
    }

    public func isBoostActive(at now: Date) -> Bool {
        guard let boostUntil else { return false }
        return now < boostUntil
    }

    public func secondsRemaining(at now: Date) -> Int {
        guard phase == .active, let activeUntil else { return 0 }
        return max(0, Int(activeUntil.timeIntervalSince(now).rounded(.up)))
    }

    public func boostSecondsRemaining(at now: Date) -> Int {
        guard let boostUntil, now < boostUntil else { return 0 }
        return max(0, Int(boostUntil.timeIntervalSince(now).rounded(.up)))
    }

    /// Alternating side, so two nodes in a row are not muscle memory.
    public var prefersTrailingEdge: Bool { cycle.isMultiple(of: 2) }
}

public enum ResonanceNodeEngine {
    /// Advances the cycle to `now`.
    ///
    /// `isForeground` is the whole reason this is a state machine rather than a timer: a
    /// node that appears and expires while the app is in the background would be a reward
    /// the player was never given the chance to take. Backgrounding schedules nothing and
    /// records no miss.
    public static func advance<R: RandomNumberGenerator>(
        _ state: ResonanceNodeState,
        now: Date,
        isForeground: Bool,
        using generator: inout R
    ) -> ResonanceNodeState {
        var state = state

        guard isForeground else {
            // An active window cannot survive backgrounding, but it is returned to waiting
            // rather than recorded as a miss.
            if state.phase == .active {
                state = ResonanceNodeState(phase: .waiting, cycle: state.cycle, boostUntil: state.boostUntil)
            }
            return clearedBoostIfExpired(state, now: now)
        }

        switch state.phase {
        case .waiting:
            guard let appearsAt = state.appearsAt else {
                let delay = state.cycle == 0
                    ? Balance.resonanceNodeFirstDelay
                    : TimeInterval.random(
                        in: Balance.resonanceNodeMinimumDelay...Balance.resonanceNodeMaximumDelay,
                        using: &generator
                    )
                state = ResonanceNodeState(
                    phase: .waiting,
                    cycle: state.cycle,
                    appearsAt: now.addingTimeInterval(delay),
                    boostUntil: state.boostUntil
                )
                return state
            }
            if now >= appearsAt {
                state = ResonanceNodeState(
                    phase: .active,
                    cycle: state.cycle,
                    activeUntil: now.addingTimeInterval(Balance.resonanceNodeActiveWindow),
                    boostUntil: state.boostUntil
                )
            }

        case .active:
            if let activeUntil = state.activeUntil, now >= activeUntil {
                state = ResonanceNodeState(
                    phase: .missed,
                    cycle: state.cycle,
                    boostUntil: state.boostUntil,
                    settlesAt: now.addingTimeInterval(Balance.resonanceNodeSettleDelay)
                )
            }

        case .claimed, .missed:
            if let settlesAt = state.settlesAt, now >= settlesAt {
                state = ResonanceNodeState(
                    phase: .waiting,
                    cycle: state.cycle + 1,
                    boostUntil: state.boostUntil
                )
            }
        }

        return clearedBoostIfExpired(state, now: now)
    }

    /// Claims an active node. A claim outside the window is not an error and not a reward:
    /// it does nothing, so a mistimed press can never fabricate a boost.
    public static func claim(_ state: ResonanceNodeState, now: Date) -> ResonanceNodeState {
        guard state.phase == .active else { return state }
        return ResonanceNodeState(
            phase: .claimed,
            cycle: state.cycle,
            boostUntil: now.addingTimeInterval(Balance.resonanceNodeBoostDuration),
            settlesAt: now.addingTimeInterval(Balance.resonanceNodeSettleDelay)
        )
    }

    /// Output multiplier to apply to both tap and automation while a boost runs.
    public static func outputMultiplier(_ state: ResonanceNodeState, at now: Date) -> Double {
        state.isBoostActive(at: now) ? Balance.resonanceNodeMultiplier : 1
    }

    private static func clearedBoostIfExpired(
        _ state: ResonanceNodeState,
        now: Date
    ) -> ResonanceNodeState {
        guard let boostUntil = state.boostUntil, now >= boostUntil else { return state }
        return ResonanceNodeState(
            phase: state.phase,
            cycle: state.cycle,
            appearsAt: state.appearsAt,
            activeUntil: state.activeUntil,
            boostUntil: nil,
            settlesAt: state.settlesAt
        )
    }
}
