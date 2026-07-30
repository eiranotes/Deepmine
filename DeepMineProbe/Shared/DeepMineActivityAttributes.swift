import ActivityKit
import Foundation

struct DeepMineActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        let snapshot: GameSurfaceSnapshot
    }

    let sessionID: UUID
    let startedAt: Date
    let endsAt: Date
}
