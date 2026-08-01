import Foundation

/// The clicker's write path into `PlayerState`. Everything that moves the player down
/// goes through here, so ore and position can never drift apart.
public enum MiningLoop {
    /// Visible timers may keep an old local tick while an offline settlement has already
    /// advanced the persisted clock. Always use the newer anchor so foregrounding cannot
    /// pay the background interval twice.
    public static func unsettledVisibleSeconds(
        lastTick: Date,
        lastSettledAt: Date?,
        now: Date
    ) -> TimeInterval {
        let anchor = max(lastTick, lastSettledAt ?? lastTick)
        return max(0, now.timeIntervalSince(anchor))
    }

    /// One tap on the rock.
    @discardableResult
    public static func strike<R: RandomNumberGenerator>(
        hitWeakPoint: Bool = false,
        outputMultiplier: Double = 1,
        using generator: inout R,
        in state: inout PlayerState
    ) -> MineFaceUpdate {
        let update = MineFaceEngine.strike(
            face: state.mineFace,
            power: power(for: state).scaled(by: outputMultiplier),
            hitWeakPoint: hitWeakPoint,
            equipment: state.equipment,
            modifications: state.equipmentModifications,
            using: &generator
        )
        commit(update, to: &state)
        return update
    }

    /// Automation for an elapsed span — one on-screen tick, or the whole time the app
    /// was closed. Deliberately the same call in both cases.
    ///
    /// Pass `at` with the moment the span ended whenever the caller is settling real
    /// elapsed time. It moves the settlement mark forward, and without it the same
    /// seconds are paid twice: once by the on-screen tick, and again by the offline
    /// settlement that still believes it is owed everything since the last relaunch.
    @discardableResult
    public static func advance(
        seconds: TimeInterval,
        at now: Date? = nil,
        outputMultiplier: Double = 1,
        in state: inout PlayerState
    ) -> MineFaceUpdate {
        let update = MineFaceEngine.advance(
            face: state.mineFace,
            power: power(for: state).scaled(by: outputMultiplier),
            seconds: seconds,
            equipment: state.equipment,
            modifications: state.equipmentModifications
        )
        commit(update, to: &state)
        if let now { state.lastSettledAt = now }
        return update
    }

    public static func power(for state: PlayerState) -> StrikePower {
        StrikeEngine.power(
            equipment: state.equipment,
            permanent: state.permanentUpgrades,
            modifications: state.equipmentModifications,
            prestigeMultiplier: PrestigeEngine.memoryMultiplier(
                level: state.excavationMemoryLevel
            )
        )
    }

    private static func commit(_ update: MineFaceUpdate, to state: inout PlayerState) {
        state.mineFace = update.face
        state.deepestSegmentIndex = max(state.deepestSegmentIndex, update.face.segmentIndex)
        if update.segmentsBroken > 0, state.runSegmentsBroken < Int.max {
            state.runSegmentsBroken = state.runSegmentsBroken
                > Int.max - update.segmentsBroken
                ? Int.max
                : state.runSegmentsBroken + update.segmentsBroken
        }
        let gained = update.oreGained.doubleValue
        if !update.oreGained.isZero, gained.isFinite, gained > 0 {
            state.resources.ore = state.resources.ore <= Double.greatestFiniteMagnitude - gained
                ? state.resources.ore + gained
                : Double.greatestFiniteMagnitude
        }

        // Breaking through is how depth and regions are earned now, so it is also where
        // the thresholds that watch them resolve. Evaluating only on session completion
        // left a player who never focuses unable to earn a depth badge they had already
        // dug past (D-047). Evaluation is idempotent, so doing it here pays nothing twice.
        guard update.segmentsBroken > 0 else { return }
        WorldProgression.unlockThemesForCurrentDepth(in: &state)
        AchievementEngine.evaluate(in: &state)
    }
}
