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
    /// Minutes a day spent tapping the rock. Without this the model describes a game
    /// with no hand in it, and every conclusion about the clicker economy is drawn from
    /// automation alone.
    let dailyTapMinutes: Int
    /// Hours a day the app is open. Time outside it settles through the offline path,
    /// where the cap and the efficiency penalty actually apply.
    let dailyOpenHours: Double
}
struct BalanceDayRow: Equatable, Sendable {
    let persona: PersonaID
    let day, sessions, completed, abandoned, focusedMinutes: Int
    let oreEarned, oreBalance: Double
    let currentDepth, recordDepth, drill, cart, lamp, prestige, fatiguedMinutes: Int

    var csv: String {
        [persona.rawValue, "\(day)", "\(sessions)", "\(completed)", "\(abandoned)",
         "\(focusedMinutes)", decimal(oreEarned), decimal(oreBalance), "\(currentDepth)",
         "\(recordDepth)", "\(drill)", "\(cart)", "\(lamp)", "\(prestige)",
         "\(fatiguedMinutes)"].joined(separator: ",")
    }

}
struct PersonaSummary: Equatable, Sendable {
    let persona: PersonaID
    let totalSessions: Int
    let firstUpgradeSession, firstPrestigeDay: Int?
    let totalOreEarned, lifetimeFocusCredits, finalOre: Double
    let finalCurrentDepth, finalRecordDepth: Int
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
        let header = "persona,day,sessions,completed,abandoned,focused_minutes,ore_earned,ore_balance,current_depth,record_depth,drill,cart,lamp,prestige,fatigued_minutes"
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
