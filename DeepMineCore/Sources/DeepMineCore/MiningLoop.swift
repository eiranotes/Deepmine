import Foundation

/// The clicker's write path into `PlayerState`. Everything that moves the player down
/// goes through here, so ore and position can never drift apart.
public enum MiningLoop {
    /// One tap on the rock.
    @discardableResult
    public static func strike<R: RandomNumberGenerator>(
        hitWeakPoint: Bool = false,
        using generator: inout R,
        in state: inout PlayerState
    ) -> MineFaceUpdate {
        let update = MineFaceEngine.strike(
            face: state.mineFace,
            power: power(for: state),
            hitWeakPoint: hitWeakPoint,
            using: &generator
        )
        commit(update, to: &state)
        return update
    }

    /// Automation for an elapsed span — one on-screen tick, or the whole time the app
    /// was closed. Deliberately the same call in both cases.
    @discardableResult
    public static func advance(
        seconds: TimeInterval,
        in state: inout PlayerState
    ) -> MineFaceUpdate {
        let update = MineFaceEngine.advance(
            face: state.mineFace,
            power: power(for: state),
            seconds: seconds
        )
        commit(update, to: &state)
        return update
    }

    public static func power(for state: PlayerState) -> StrikePower {
        StrikeEngine.power(
            equipment: state.equipment,
            permanent: state.permanentUpgrades,
            prestigeMultiplier: PrestigeEngine.memoryMultiplier(
                level: state.excavationMemoryLevel
            )
        )
    }

    private static func commit(_ update: MineFaceUpdate, to state: inout PlayerState) {
        state.mineFace = update.face
        guard !update.oreGained.isZero else { return }
        let gained = update.oreGained.doubleValue
        guard gained.isFinite, gained > 0 else { return }
        state.resources.ore = state.resources.ore <= Double.greatestFiniteMagnitude - gained
            ? state.resources.ore + gained
            : Double.greatestFiniteMagnitude
    }
}
