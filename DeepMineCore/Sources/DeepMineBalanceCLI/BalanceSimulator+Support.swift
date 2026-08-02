import Foundation
import DeepMineCore

extension BalanceSimulator {
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

    static func buyEverythingAffordable(
        persona: PersonaDefinition,
        day: Int,
        state: inout PlayerState,
        firstUpgrade: inout Int?,
        totalSessions: Int
    ) {
        var event = 300
        while let target = UpgradeAdvisor.recommendForMining(for: state) {
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
            buyRefinementWhereverUnlocked(state: &state)
        }
    }

    static func buyRefinementWhereverUnlocked(state: inout PlayerState) {
        var guardrail = 0
        while guardrail < 512 {
            guardrail += 1
            let bought = EquipmentKind.allCases.contains { kind in
                if case .refined = RefinementEngine.purchase(kind, in: &state) { return true }
                return false
            }
            if !bought { return }
        }
    }

    static func buyPermanentUpgrades(
        persona: PersonaDefinition,
        day: Int,
        eventBase: Int,
        state: inout PlayerState
    ) {
        let order: [PermanentUpgradeKind] = [
            .excavationMemory,
            .resonanceDetection,
            .compressedTime
        ]
        var event = eventBase
        var guardrail = 0
        while guardrail < 128 {
            guardrail += 1
            var purchased = false
            for upgrade in order {
                let result = PrestigeEngine.purchase(
                    PermanentUpgradeCommand(
                        id: stableID(
                            persona: offsetID(persona.id),
                            day: day,
                            event: event
                        ),
                        upgrade: upgrade
                    ),
                    in: &state
                )
                event += 1
                if case .purchased = result {
                    purchased = true
                    break
                }
            }
            if !purchased { return }
        }
    }

    static func nextRecommendation(
        persona _: PersonaDefinition,
        after _: Int,
        dailyMinutes _: Int,
        state: PlayerState
    ) throws -> UpgradeRecommendation? {
        UpgradeAdvisor.recommendForMining(for: state)
    }

    static func settleSessionMining(
        projectedReward: RewardResult,
        completedAt: Date,
        state: inout PlayerState
    ) -> (reward: RewardResult, ore: Double) {
        let creditedSeconds = TimeInterval(projectedReward.focusedMinutes * 60)
            * sessionMiningRate(projectedReward)
        let update = creditedSeconds > 0
            ? MiningLoop.advance(seconds: creditedSeconds, at: completedAt, in: &state)
            : .empty(face: state.mineFace)
        let minedOre = update.oreGained.doubleValue
        let ore = minedOre.isFinite ? max(0, minedOre) : Double.greatestFiniteMagnitude
        return (
            RewardResult(
                completionID: projectedReward.completionID,
                focusedMinutes: projectedReward.focusedMinutes,
                focusCredits: projectedReward.focusCredits,
                ore: ore,
                breakdown: projectedReward.breakdown,
                wasDuplicate: projectedReward.wasDuplicate
            ),
            ore
        )
    }

    static func sessionMiningRate(_ reward: RewardResult) -> Double {
        let equipment = max(1, reward.breakdown.equipment)
        let vein = max(1, reward.breakdown.vein)
        let rate = reward.breakdown.combinedMultiplier / equipment / vein
        return rate.isFinite ? max(0, rate) : Double.greatestFiniteMagnitude
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
