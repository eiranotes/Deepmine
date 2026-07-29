import ActivityKit
import Foundation

enum LiveActivityLifecycle {
    static func start(duration: TimeInterval = ProbeConstants.probeDuration) async throws -> String {
        try await replaceAll(duration: duration)
    }

    private static func endAll() async throws {
        for _ in 0..<3 {
            let active = Activity<DeepMineActivityAttributes>.activities
            guard !active.isEmpty else { return }
            for activity in active {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            await Task.yield()
        }

        let remaining = Activity<DeepMineActivityAttributes>.activities.count
        guard remaining == 0 else {
            throw LiveActivityLifecycleError.activitiesRemain(remaining)
        }
    }

    static func restart(duration: TimeInterval = ProbeConstants.probeDuration) async throws -> String {
        try await replaceAll(duration: duration)
    }

    private static func replaceAll(duration: TimeInterval) async throws -> String {
        let lock = try await Task.detached {
            try ProbeProcessLock.acquire(
                filename: ProbeConstants.liveActivityLifecycleLockFilename
            )
        }.value
        defer { lock.release() }

        try await endAll()
        return try requestNew(duration: duration)
    }

    private static func requestNew(duration: TimeInterval) throws -> String {
        let startedAt = Date()
        let endsAt = startedAt.addingTimeInterval(duration)
        let attributes = DeepMineActivityAttributes(
            sessionID: UUID(),
            startedAt: startedAt,
            endsAt: endsAt
        )
        let state = DeepMineActivityAttributes.ContentState(
            phase: .mining,
            expectedReward: 100,
            depth: 148,
            streakDays: 7,
            planID: "deep",
            themeID: "zone-3"
        )
        let content = ActivityContent(state: state, staleDate: endsAt)
        let activity = try Activity<DeepMineActivityAttributes>.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
        return activity.id
    }
}

enum LiveActivityLifecycleError: LocalizedError {
    case activitiesRemain(Int)

    var errorDescription: String? {
        switch self {
        case .activitiesRemain(let count):
            "Unable to end \(count) existing DeepMine Live Activities before requesting a new one."
        }
    }
}
