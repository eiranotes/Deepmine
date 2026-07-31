import Foundation
import DeepMineCore
enum PersonaID: String, CaseIterable, Sendable {
    case light
    case standard
    case heavy
    case irregular

    var koreanName: String {
        switch self {
        case .light: "라이트"
        case .standard: "스탠다드"
        case .heavy: "헤비"
        case .irregular: "불규칙"
        }
    }
}
struct PersonaDefinition: Sendable {
    let id: PersonaID
    let lengths: [SessionLength]
    let abandonRate: Double
    let activeEveryDays: Int
    let dailyGoalMinutes: Int
    let plan: MinePlan
}
struct BalanceDayRow: Equatable, Sendable {
    let persona: PersonaID
    let day, sessions, completed, abandoned, focusedMinutes: Int
    let oreEarned, oreBalance: Double
    let depth, drill, cart, lamp, prestige, fatiguedMinutes: Int

    var csv: String {
        [persona.rawValue, "\(day)", "\(sessions)", "\(completed)", "\(abandoned)",
         "\(focusedMinutes)", decimal(oreEarned), decimal(oreBalance), "\(depth)",
         "\(drill)", "\(cart)", "\(lamp)", "\(prestige)", "\(fatiguedMinutes)"].joined(separator: ",")
    }
}
struct PersonaSummary: Equatable, Sendable {
    let persona: PersonaID
    let totalSessions: Int
    let firstUpgradeSession, firstPrestigeDay: Int?
    let totalOreEarned, lifetimeFocusCredits, finalOre: Double
    let finalDepth: Int
    let equipment: EquipmentLevels
    let prestigeIndex, fatiguedMinutes: Int
}
struct EqualTimeRow: Equatable, Sendable {
    let length: SessionLength
    let sessions: Int
    let minutes: Int
    let ore: Double
}
struct BalanceSimulationResult: Equatable, Sendable {
    let rows: [BalanceDayRow]
    let summaries: [PersonaSummary]
    let equalTime: [EqualTimeRow]

    var csv: String {
        let header = "persona,day,sessions,completed,abandoned,focused_minutes,ore_earned,ore_balance,depth,drill,cart,lamp,prestige,fatigued_minutes"
        return ([header] + rows.map(\.csv)).joined(separator: "\n") + "\n"
    }

    var heavyLightOreGap: Double {
        guard let heavy = summaries.first(where: { $0.persona == .heavy })?.totalOreEarned,
              let light = summaries.first(where: { $0.persona == .light })?.totalOreEarned,
              light > 0 else { return .infinity }
        return heavy / light
    }

    var heavyLightFocusGap: Double {
        guard let heavy = summaries.first(where: { $0.persona == .heavy })?.lifetimeFocusCredits,
              let light = summaries.first(where: { $0.persona == .light })?.lifetimeFocusCredits,
              light > 0 else { return .infinity }
        return heavy / light
    }
}
enum BalanceSimulator {
    static let personas: [PersonaDefinition] = [
        PersonaDefinition(id: .light, lengths: [.minutes25], abandonRate: 0.20, activeEveryDays: 1, dailyGoalMinutes: 25, plan: .safe),
        PersonaDefinition(id: .standard, lengths: [.minutes25, .minutes25, .minutes50], abandonRate: 0.10, activeEveryDays: 1, dailyGoalMinutes: 100, plan: .safe),
        PersonaDefinition(id: .heavy, lengths: [.minutes25, .minutes25, .minutes50, .minutes50, .minutes50, .minutes50], abandonRate: 0.05, activeEveryDays: 1, dailyGoalMinutes: 100, plan: .safe),
        PersonaDefinition(id: .irregular, lengths: [.minutes50], abandonRate: 0.20, activeEveryDays: 2, dailyGoalMinutes: 50, plan: .survey)
    ]
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
        var totalFatigued = 0
        for day in 1...max(0, days) {
            var dailyOre = 0.0
            var dailyFocused = 0
            var dailyFatigued = 0
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
                    _ = try StreakEngine.recordSession(
                        focusedMinutes: reward.focusedMinutes,
                        at: simulationDate(day: day, minute: sessionIndex),
                        plan: persona.plan, outcome: outcome, in: &state,
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
                    if PrestigeEngine.preview(for: state).isEligible {
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
            rows.append(BalanceDayRow(
                persona: persona.id, day: day,
                sessions: isActive ? persona.lengths.count : 0,
                completed: completed, abandoned: abandoned,
                focusedMinutes: dailyFocused, oreEarned: dailyOre,
                oreBalance: state.resources.ore, depth: state.depthMeters,
                drill: state.equipment.drill, cart: state.equipment.cart,
                lamp: state.equipment.lamp, prestige: state.prestigeIndex,
                fatiguedMinutes: dailyFatigued
            ))
        }
        return (rows, PersonaSummary(
            persona: persona.id, totalSessions: totalSessions,
            firstUpgradeSession: firstUpgrade, firstPrestigeDay: firstPrestige,
            totalOreEarned: totalOre, lifetimeFocusCredits: state.lifetimeFocusCredits,
            finalOre: state.resources.ore, finalDepth: state.depthMeters,
            equipment: state.equipment, prestigeIndex: state.prestigeIndex,
            fatiguedMinutes: totalFatigued
        ))
    }
    private static func nextRecommendation(
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
    private static func makeInput(
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
    private static func equalTimeComparison() throws -> [EqualTimeRow] {
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
    private static func randomUnit(_ generator: inout SeededGenerator) -> Double {
        Double(generator.next() >> 11) / 9_007_199_254_740_992
    }
    private static func stableID(persona: Int, day: Int, event: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-%04X-%04X-%012X", persona, day, event))!
    }
    private static func offsetID(_ persona: PersonaID) -> Int {
        PersonaID.allCases.firstIndex(of: persona)! + 1
    }
    private static func simulationDate(day: Int, minute: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval((day - 1) * 86_400 + minute * 60))
    }
}
private func decimal(_ value: Double) -> String { String(format: "%.6f", value) }
private func cliValue(_ name: String, arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
    return arguments[index + 1]
}
let arguments = CommandLine.arguments
let seed = UInt64(cliValue("--seed", arguments: arguments) ?? "260729") ?? 260_729
let days = Int(cliValue("--days", arguments: arguments) ?? "30") ?? 30
let output = cliValue("--output", arguments: arguments) ?? "/tmp/deepmine-balance.csv"
do {
    let result = try BalanceSimulator.run(seed: seed, days: days)
    try result.csv.write(toFile: output, atomically: true, encoding: .utf8)
    for summary in result.summaries {
        print("\(summary.persona.koreanName): firstUpgrade=\(summary.firstUpgradeSession.map(String.init) ?? "-") firstPrestigeDay=\(summary.firstPrestigeDay.map(String.init) ?? "-") ore=\(decimal(summary.totalOreEarned)) fatigue=\(summary.fatiguedMinutes)")
    }
    print("heavy/light ore gap: \(decimal(result.heavyLightOreGap))x")
    print("heavy/light focus gap: \(decimal(result.heavyLightFocusGap))x")
    for row in result.equalTime {
        print("equal 150m \(row.length.rawValue): \(decimal(row.ore)) ore")
    }
    print("csv: \(output)")
} catch {
    FileHandle.standardError.write(Data("simulation failed: \(error)\n".utf8))
}
