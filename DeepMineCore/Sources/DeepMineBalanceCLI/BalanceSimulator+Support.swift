import Foundation
import DeepMineCore

extension BalanceSimulator {
    /// Runs a day's worth of real strikes. Tapping is simulated tap by tap rather than as
    /// an averaged damage figure so criticals, weak points and the impact meter land in
    /// the model exactly as they land in the game.
    static func tapForADay(
        persona: PersonaDefinition,
        state: inout PlayerState,
        generator: inout SeededGenerator
    ) -> Double {
        let taps = Int(Double(persona.dailyTapMinutes) * 60 * tapsPerSecond)
        guard taps > 0 else { return 0 }
        var ore = 0.0
        for _ in 0..<taps {
            let aimed = randomUnit(&generator) < weakPointHitRate
            let update = MiningLoop.strike(hitWeakPoint: aimed, using: &generator, in: &state)
            ore += update.oreGained.doubleValue
        }
        return ore
    }

    /// Spends the day's ore. A player with ore in hand and an affordable upgrade buys it,
    /// so leftover ore in the summary means the ladder is gated, not that nobody shopped.
    static func buyEverythingAffordable(
        persona: PersonaDefinition,
        day: Int,
        state: inout PlayerState,
        firstUpgrade: inout Int?,
        totalSessions: Int
    ) {
        var event = 300
        while true {
            let affordable = EquipmentKind.allCases
                .compactMap { EquipmentEngine.quote(for: $0, in: state) }
                .filter { $0.cost <= state.resources.ore }
                .min { $0.cost < $1.cost }
            guard let target = affordable else { return }
            let purchase = EquipmentEngine.purchase(
                UpgradePurchaseCommand(
                    id: stableID(persona: offsetID(persona.id), day: day, event: event),
                    equipment: target.equipment
                ),
                in: &state
            )
            event += 1
            guard case .purchased = purchase else { return }
            if firstUpgrade == nil { firstUpgrade = totalSessions }
        }
    }

    static func nextRecommendation(
        persona: PersonaDefinition,
        after index: Int,
        dailyMinutes: Int,
        state: PlayerState
    ) throws -> UpgradeRecommendation? {
        let length = persona.lengths[(index + 1) % persona.lengths.count]
        let input = makeInput(
            id: stableID(persona: offsetID(persona.id), day: 0, event: index),
            outcome: .completed, length: length, plan: persona.plan,
            dailySession: index + 2, dailyMinutes: dailyMinutes,
            resonance: state.resonanceBoostPending, vein: nil, state: state
        )
        return try UpgradeAdvisor.recommend(for: state, nextSession: input)
    }

    static func makeInput(
        id: UUID, outcome: SessionOutcome, length: SessionLength, plan: MinePlan,
        dailySession: Int, dailyMinutes: Int, resonance: Bool, vein: VeinKind?,
        state: PlayerState
    ) -> RewardInput {
        RewardInput(
            completionID: id, outcome: outcome, sessionLength: length,
            plan: plan, verificationGrade: .sealed,
            growthFocusCredits: state.lifetimeFocusCredits,
            streakDays: state.streakDays, dailySessionNumber: dailySession,
            equipment: state.equipment, vein: vein,
            resonanceBoostActive: resonance,
            permanentUpgrades: state.permanentUpgrades
        )
    }

    static func equalTimeComparison() throws -> [EqualTimeRow] {
        let examples: [(SessionLength, Int)] = [(.minutes15, 10), (.minutes25, 6), (.minutes50, 3)]
        return try examples.map { length, sessions in
            var lifetime = 0.0
            var ore = 0.0
            for index in 0..<sessions {
                let input = RewardInput(
                    completionID: stableID(persona: 9, day: length.minutes, event: index),
                    outcome: .completed, sessionLength: length, plan: .safe,
                    verificationGrade: .sealed, growthFocusCredits: lifetime,
                    streakDays: 1, dailySessionNumber: 1, equipment: EquipmentLevels(),
                    vein: nil, resonanceBoostActive: false
                )
                let reward = try RewardCalculator.calculate(input)
                ore += reward.ore
                lifetime += reward.focusCredits
            }
            return EqualTimeRow(length: length, sessions: sessions, minutes: 150, ore: ore)
        }
    }

    static func randomUnit(_ generator: inout SeededGenerator) -> Double {
        Double(generator.next() >> 11) / 9_007_199_254_740_992
    }

    static func stableID(persona: Int, day: Int, event: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-%04X-%04X-%012X", persona, day, event))!
    }

    static func offsetID(_ persona: PersonaID) -> Int {
        PersonaID.allCases.firstIndex(of: persona)! + 1
    }

    static func simulationDate(day: Int, minute: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval((day - 1) * 86_400 + minute * 60))
    }
}
