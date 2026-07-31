import ActivityKit
import AlarmKit
import Foundation

struct DeepMineActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        let snapshot: GameSurfaceSnapshot
    }

    let sessionID: UUID
    let startedAt: Date
    let endsAt: Date
}

struct DeepMineAlarmMetadata: AlarmMetadata {
    let source: String
    let snapshot: GameSurfaceSnapshot?
}

struct DeepMineAlarmActivityProjection {
    let snapshot: GameSurfaceSnapshot
    let startedAt: Date
    let endsAt: Date
    let isStale: Bool

    init(
        metadata: DeepMineAlarmMetadata?,
        state: AlarmPresentationState,
        now: Date = Date()
    ) {
        let timing: (Date, Date, Bool) = switch state.mode {
        case .countdown(let countdown):
            (countdown.startDate, countdown.fireDate, false)
        case .paused(let paused):
            (
                now.addingTimeInterval(-paused.previouslyElapsedDuration),
                now.addingTimeInterval(max(
                    1,
                    paused.totalCountdownDuration - paused.previouslyElapsedDuration
                )),
                false
            )
        case .alert:
            (
                metadata?.snapshot?.timerStartedAt.map(Date.init(timeIntervalSince1970:))
                    ?? now,
                metadata?.snapshot?.timerEndsAt.map(Date.init(timeIntervalSince1970:))
                    ?? now,
                true
            )
        @unknown default:
            (now, now, true)
        }
        startedAt = timing.0
        endsAt = timing.1
        isStale = timing.2
        snapshot = metadata?.snapshot ?? Self.fallbackSnapshot(
            startedAt: startedAt,
            endsAt: endsAt,
            now: now
        )
    }

    private static func fallbackSnapshot(
        startedAt: Date,
        endsAt: Date,
        now: Date
    ) -> GameSurfaceSnapshot {
        GameSurfaceSnapshot(
            phase: .mining,
            sessionID: nil,
            planID: "safe",
            regionID: "entry",
            depthMeters: 0,
            expectedOre: 0,
            earnedOre: 0,
            streakDays: 0,
            timerStartedAt: startedAt.timeIntervalSince1970,
            timerEndsAt: endsAt.timeIntervalSince1970,
            verificationGradeID: "open",
            veinID: nil,
            upgradeRecommendation: nil,
            todayFocusedMinutes: 0,
            todayGoalMinutes: 100,
            generatedAt: now.timeIntervalSince1970,
            staleAfter: endsAt.timeIntervalSince1970
        )
    }
}
