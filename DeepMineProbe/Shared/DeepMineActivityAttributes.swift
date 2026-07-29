import ActivityKit
import Foundation

enum ProbeSessionPhase: String, Codable, Hashable, Sendable {
    case mining
    case completed
}

struct DeepMineActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        let phase: ProbeSessionPhase
        let expectedReward: Int
        let depth: Int
        let streakDays: Int
        let planID: String
        let themeID: String
    }

    let sessionID: UUID
    let startedAt: Date
    let endsAt: Date
}
