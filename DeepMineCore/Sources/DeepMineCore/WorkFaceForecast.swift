import Foundation

/// What the current rock is worth and how long it has left.
///
/// A clicker's first screen has to answer "why am I hitting this" before it can ask for a
/// second tap. Reading it off the shaft is the whole point of D-056: the reward for the
/// layer in progress, the time it takes without any input, and the fact that both change
/// when equipment is bought.
public struct WorkFaceForecast: Equatable, Sendable {
    /// Ore the current segment pays when it breaks, with the freight modification applied.
    public let expectedOre: BigNumber
    public let remainingIntegrity: BigNumber
    /// Seconds for automation alone to break the rock. `nil` when nothing is automated —
    /// a cart at base level hauls nothing, and a fabricated ETA would promise idle income
    /// the player has not bought yet.
    public let automaticSecondsToBreak: TimeInterval?
    /// Taps needed at the current tap power, ignoring criticals and the impact meter so
    /// the number is a ceiling rather than an optimistic estimate.
    public let tapsToBreak: Int?

    public init(
        expectedOre: BigNumber,
        remainingIntegrity: BigNumber,
        automaticSecondsToBreak: TimeInterval?,
        tapsToBreak: Int?
    ) {
        self.expectedOre = expectedOre
        self.remainingIntegrity = remainingIntegrity
        self.automaticSecondsToBreak = automaticSecondsToBreak
        self.tapsToBreak = tapsToBreak
    }
}

extension MiningLoop {
    public static func forecast(for state: PlayerState) -> WorkFaceForecast {
        let power = power(for: state)
        let remaining = state.mineFace.remainingIntegrity
        let oreMultiplier = max(1, power.oreMultiplier)
        let expectedOre = state.mineFace.segment.oreYield * oreMultiplier

        let seconds: TimeInterval?
        if power.damagePerSecond > .zero, remaining > .zero {
            let value = (remaining / power.damagePerSecond).doubleValue
            seconds = value.isFinite && value >= 0 ? value : nil
        } else {
            seconds = nil
        }

        let taps: Int?
        if power.tapDamage > .zero, remaining > .zero {
            let value = (remaining / power.tapDamage).doubleValue
            taps = value.isFinite && value < Double(Int.max)
                ? max(1, Int(value.rounded(.up)))
                : nil
        } else {
            taps = nil
        }

        return WorkFaceForecast(
            expectedOre: expectedOre,
            remainingIntegrity: remaining,
            automaticSecondsToBreak: seconds,
            tapsToBreak: taps
        )
    }
}
