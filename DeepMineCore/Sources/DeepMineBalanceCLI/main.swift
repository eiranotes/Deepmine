import Foundation
import DeepMineCore

/// When a simulated player takes a reset.
///
/// Prestige returns the player to the surface, so how eagerly it is taken decides which
/// segments they spend the run on — and segment ore compounds with depth. Comparing the
/// two policies is what separates "heavy players earn less" from "the reset policy the
/// simulation assumes earns less".
enum PrestigePolicy: String {
    /// Reset the moment it is available. What the simulation has always modelled.
    case immediate
    /// Never reset. An upper bound on staying deep.
    case never

    var takesPrestige: Bool { self == .immediate }
}

enum BalanceSimulator {
    /// Set from the command line before `run`.
    nonisolated(unsafe) static var prestigePolicy: PrestigePolicy = .immediate

    static let personas: [PersonaDefinition] = [
        PersonaDefinition(id: .light, lengths: [.minutes25], abandonRate: 0.20, activeEveryDays: 1, dailyGoalMinutes: 25, plan: .safe, dailyTapMinutes: 5, dailyOpenHours: 0.5),
        PersonaDefinition(id: .standard, lengths: [.minutes25, .minutes25, .minutes50], abandonRate: 0.10, activeEveryDays: 1, dailyGoalMinutes: 100, plan: .safe, dailyTapMinutes: 15, dailyOpenHours: 1),
        PersonaDefinition(id: .heavy, lengths: [.minutes25, .minutes25, .minutes50, .minutes50, .minutes50, .minutes50], abandonRate: 0.05, activeEveryDays: 1, dailyGoalMinutes: 100, plan: .safe, dailyTapMinutes: 40, dailyOpenHours: 3),
        PersonaDefinition(id: .irregular, lengths: [.minutes50], abandonRate: 0.20, activeEveryDays: 2, dailyGoalMinutes: 50, plan: .survey, dailyTapMinutes: 10, dailyOpenHours: 0.75)
    ]
    /// A sustained tapping rate. Faster is possible in bursts; this is what an hour of
    /// play actually averages.
    static let tapsPerSecond = 5.0
    /// Share of taps that land on the segment's weak point when one exists. A player
    /// aiming for it hits often, not always.
    static let weakPointHitRate = 0.6
    static func run(seed: UInt64, days: Int) throws -> BalanceSimulationResult {
        var rows: [BalanceDayRow] = []
        var summaries: [PersonaSummary] = []
        for (offset, persona) in personas.enumerated() {
            let result = try simulate(persona, seed: seed &+ UInt64(offset + 1), days: days)
            rows.append(contentsOf: result.rows)
            summaries.append(result.summary)
        }
        return BalanceSimulationResult(
            rows: rows,
            summaries: summaries,
            equalTime: try equalTimeComparison()
        )
    }
    private static func simulate(
        _ persona: PersonaDefinition,
        seed: UInt64,
        days: Int
    ) throws -> (rows: [BalanceDayRow], summary: PersonaSummary) {
        var state = PlayerState(dailyGoalMinutes: persona.dailyGoalMinutes)
        var generator = SeededGenerator(seed: seed)
        var rows: [BalanceDayRow] = []
        var totalSessions = 0
        var firstUpgrade: Int?
        var firstPrestige: Int?
        var totalOre = 0.0
        let totalFatigued = 0
        for day in 1...max(0, days) {
            var dailyOre = 0.0
            var dailyFocused = 0
            let dailyFatigued = 0
            var completed = 0
            var abandoned = 0
            let isActive = (day - 1).isMultiple(of: persona.activeEveryDays)
            if isActive {
                for (sessionIndex, length) in persona.lengths.enumerated() {
                    totalSessions += 1
                    let abandons = randomUnit(&generator) < persona.abandonRate
                    let outcome: SessionOutcome = abandons
                        ? .abandoned(elapsedMinutes: length.minutes)
                        : .completed
                    if abandons { abandoned += 1 } else { completed += 1 }
                    let resonance = WorldProgression.consumeResonanceBoost(in: &state)
                    let roll = VeinEngine.rollAfterCompletion(
                        outcome: outcome, plan: persona.plan, state: &state, using: &generator
                    )
                    let input = makeInput(
                        id: stableID(persona: offsetID(persona.id), day: day, event: sessionIndex),
                        outcome: outcome, length: length, plan: persona.plan,
                        dailySession: sessionIndex + 1, dailyMinutes: dailyFocused,
                        resonance: resonance, vein: roll.vein, state: state
                    )
                    let reward = try RewardCalculator.calculate(input)
                    try ProgressionEngine.apply(
                        reward: reward, input: input,
                        completedAt: simulationDate(day: day, minute: sessionIndex), to: &state
                    )
                    try MiningStreak.record(
                        at: simulationDate(day: day, minute: sessionIndex),
                        in: &state,
                        calendar: Calendar(identifier: .gregorian),
                        timeZone: TimeZone(secondsFromGMT: 0)!
                    )
                    if let vein = roll.vein {
                        WorldProgression.apply(
                            vein: vein, effectID: input.completionID,
                            regionIndex: WorldProgression.region(forDepth: state.depthMeters).index,
                            to: &state
                        )
                    }
                    dailyFocused += reward.focusedMinutes
                    dailyOre += reward.ore
                    totalOre += reward.ore
                    if let recommendation = try nextRecommendation(
                        persona: persona, after: sessionIndex, dailyMinutes: dailyFocused,
                        state: state
                    ) {
                        let purchase = EquipmentEngine.purchase(
                            UpgradePurchaseCommand(
                                id: stableID(persona: offsetID(persona.id), day: day, event: 100 + sessionIndex),
                                equipment: recommendation.equipment
                            ),
                            in: &state
                        )
                        if case .purchased = purchase, firstUpgrade == nil { firstUpgrade = totalSessions }
                    }
                    if prestigePolicy.takesPrestige,
                       PrestigeEngine.preview(for: state).isEligible {
                        let prestige = PrestigeEngine.prestige(
                            PrestigeCommand(id: stableID(
                                persona: offsetID(persona.id), day: day, event: 200 + sessionIndex
                            )),
                            in: &state
                        )
                        if case .prestiged = prestige, firstPrestige == nil { firstPrestige = day }
                    }
                }
            }
            // A day of play, in the order it happens: the player opens the app and taps,
            // the mine keeps running while it is open, and the rest of the day settles
            // through the offline path where the cap and the efficiency penalty apply.
            //
            // Paying a flat 86,400 seconds of uncapped automation, as this once did,
            // models a game that does not exist and hides both the cap and the hand.
            let handUpdate = tapForADay(persona: persona, state: &state, generator: &generator)
            dailyOre += handUpdate
            totalOre += handUpdate

            let openUpdate = MiningLoop.advance(
                seconds: persona.dailyOpenHours * 3_600,
                in: &state
            )
            dailyOre += openUpdate.oreGained.doubleValue
            totalOre += openUpdate.oreGained.doubleValue

            let closedStart = simulationDate(day: day, minute: 0)
            let settlement = MiningLoop.settleOffline(
                since: closedStart,
                now: closedStart.addingTimeInterval((24 - persona.dailyOpenHours) * 3_600),
                in: &state
            )
            dailyOre += settlement.oreGained.doubleValue
            totalOre += settlement.oreGained.doubleValue

            buyEverythingAffordable(
                persona: persona, day: day, state: &state, firstUpgrade: &firstUpgrade,
                totalSessions: totalSessions
            )

            // A reset is now earned by breaking rock, so it can come due on a day with no
            // session at all. Checking only after a session would model a game where
            // prestige still belongs to focus (D-045).
            if prestigePolicy.takesPrestige,
               PrestigeEngine.preview(for: state).isEligible {
                let prestige = PrestigeEngine.prestige(
                    PrestigeCommand(id: stableID(
                        persona: offsetID(persona.id), day: day, event: 900
                    )),
                    in: &state
                )
                if case .prestiged = prestige, firstPrestige == nil { firstPrestige = day }
            }

            rows.append(BalanceDayRow(
                persona: persona.id, day: day,
                sessions: isActive ? persona.lengths.count : 0,
                completed: completed, abandoned: abandoned,
                focusedMinutes: dailyFocused, oreEarned: dailyOre,
                oreBalance: state.resources.ore.doubleValue,
                currentDepth: state.depthMeters,
                recordDepth: state.recordDepthMeters,
                drill: state.equipment.drill, cart: state.equipment.cart,
                lamp: state.equipment.lamp, prestige: state.prestigeIndex,
                fatiguedMinutes: dailyFatigued
            ))
        }
        return (rows, PersonaSummary(
            persona: persona.id, totalSessions: totalSessions,
            firstUpgradeSession: firstUpgrade, firstPrestigeDay: firstPrestige,
            totalOreEarned: totalOre, lifetimeFocusCredits: state.lifetimeFocusCredits,
            finalOre: state.resources.ore.doubleValue,
            finalCurrentDepth: state.depthMeters,
            finalRecordDepth: state.recordDepthMeters,
            equipment: state.equipment, prestigeIndex: state.prestigeIndex,
            fatiguedMinutes: totalFatigued
        ))
    }
}
func decimal(_ value: Double) -> String { String(format: "%.6f", value) }
private func cliValue(_ name: String, arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
    return arguments[index + 1]
}
let arguments = CommandLine.arguments
let seed = UInt64(cliValue("--seed", arguments: arguments) ?? "260729") ?? 260_729
let days = Int(cliValue("--days", arguments: arguments) ?? "30") ?? 30
BalanceSimulator.prestigePolicy =
    PrestigePolicy(rawValue: cliValue("--prestige", arguments: arguments) ?? "immediate")
    ?? .immediate
let output = cliValue("--output", arguments: arguments) ?? "/tmp/deepmine-balance.csv"
do {
    let result = try BalanceSimulator.run(seed: seed, days: days)
    try result.csv.write(toFile: output, atomically: true, encoding: .utf8)
    for summary in result.summaries {
        print("\(summary.persona.koreanName): firstUpgrade=\(summary.firstUpgradeSession.map(String.init) ?? "-") firstPrestigeDay=\(summary.firstPrestigeDay.map(String.init) ?? "-") currentDepth=\(summary.finalCurrentDepth) recordDepth=\(summary.finalRecordDepth) ore=\(decimal(summary.totalOreEarned)) fatigue=\(summary.fatiguedMinutes)")
    }
    print("prestige policy: \(BalanceSimulator.prestigePolicy.rawValue)")
    print("heavy/light ore gap: \(decimal(result.heavyLightOreGap))x")
    print("heavy/light focus gap: \(decimal(result.heavyLightFocusGap))x")
    for row in result.equalTime {
        print("equal 150m \(row.length.rawValue): \(decimal(row.ore)) ore")
    }
    print("csv: \(output)")
} catch {
    FileHandle.standardError.write(Data("simulation failed: \(error)\n".utf8))
}
