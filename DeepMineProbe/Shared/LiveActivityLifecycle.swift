import ActivityKit
import DeepMineCore
import Foundation

enum LiveActivityLifecycle {
    static func start(duration: TimeInterval = ProbeConstants.probeDuration) async throws -> String {
        try await replaceAll(duration: duration)
    }

    static func restart(duration: TimeInterval = ProbeConstants.probeDuration) async throws -> String {
        try await replaceAll(duration: duration)
    }

    static func startSession(
        id: UUID,
        startedAt: Date,
        endsAt: Date,
        snapshot: GameSurfaceSnapshot
    ) async throws -> String {
        let lock = try await lifecycleLock()
        defer { lock.release() }
        try await endAll()
        let attributes = DeepMineActivityAttributes(
            sessionID: id,
            startedAt: startedAt,
            endsAt: endsAt
        )
        let content = try activityContent(snapshot: snapshot, staleDate: endsAt)
        return try Activity<DeepMineActivityAttributes>.request(
            attributes: attributes,
            content: content,
            pushType: nil
        ).id
    }

    static func completeSession(
        id: UUID,
        startedAt: Date,
        endsAt: Date,
        snapshot: GameSurfaceSnapshot,
        now: Date = Date()
    ) async throws {
        let lock = try await lifecycleLock()
        defer { lock.release() }
        let dismissalDate = completionDismissalDate(snapshot: snapshot, now: now)
        let content = try activityContent(snapshot: snapshot, staleDate: dismissalDate)
        let matching = Activity<DeepMineActivityAttributes>.activities.filter {
            $0.attributes.sessionID == id
        }
        if matching.isEmpty {
            let activity = try Activity<DeepMineActivityAttributes>.request(
                attributes: DeepMineActivityAttributes(
                    sessionID: id,
                    startedAt: startedAt,
                    endsAt: endsAt
                ),
                content: content,
                pushType: nil
            )
            await activity.end(content, dismissalPolicy: .after(dismissalDate))
            return
        }
        for activity in matching {
            await activity.update(content)
            await activity.end(content, dismissalPolicy: .after(dismissalDate))
        }
    }

    static func endSessionImmediately(id: UUID) async {
        for activity in Activity<DeepMineActivityAttributes>.activities
        where activity.attributes.sessionID == id {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    static func completionDismissalDate(
        snapshot: GameSurfaceSnapshot,
        now: Date
    ) -> Date {
        let requested = Date(timeIntervalSince1970: snapshot.staleAfter)
        let latest = now.addingTimeInterval(Balance.completedActivityRetentionSeconds)
        return min(max(now, requested), latest)
    }

    private static func replaceAll(duration: TimeInterval) async throws -> String {
        let lock = try await lifecycleLock()
        defer { lock.release() }
        try await endAll()
        return try requestProbe(duration: duration)
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

    private static func requestProbe(duration: TimeInterval) throws -> String {
        let startedAt = Date()
        let endsAt = startedAt.addingTimeInterval(duration)
        let snapshot = GameSurfaceSnapshot(
            phase: .mining,
            sessionID: UUID().uuidString,
            outcomeID: nil,
            planID: "deep",
            regionID: "crystal",
            depthMeters: 148,
            expectedOre: 100,
            earnedOre: 0,
            streakDays: 7,
            timerStartedAt: startedAt.timeIntervalSince1970,
            timerEndsAt: endsAt.timeIntervalSince1970,
            verificationGradeID: "sealed",
            veinID: nil,
            upgradeRecommendation: nil,
            todayFocusedMinutes: 25,
            todayGoalMinutes: 100,
            generatedAt: startedAt.timeIntervalSince1970,
            staleAfter: endsAt.timeIntervalSince1970
        )
        let attributes = DeepMineActivityAttributes(
            sessionID: UUID(),
            startedAt: startedAt,
            endsAt: endsAt
        )
        return try Activity<DeepMineActivityAttributes>.request(
            attributes: attributes,
            content: try activityContent(snapshot: snapshot, staleDate: endsAt),
            pushType: nil
        ).id
    }

    private static func activityContent(
        snapshot: GameSurfaceSnapshot,
        staleDate: Date
    ) throws -> ActivityContent<DeepMineActivityAttributes.ContentState> {
        let state = DeepMineActivityAttributes.ContentState(snapshot: snapshot)
        let encoded = try JSONEncoder().encode(state)
        guard encoded.count < Balance.activityContentMaximumBytes else {
            throw GameSurfaceSnapshotStoreError.payloadTooLarge(
                actual: encoded.count,
                limit: Balance.activityContentMaximumBytes
            )
        }
        return ActivityContent(state: state, staleDate: staleDate)
    }

    private static func lifecycleLock() async throws -> ProbeProcessLock {
        try await Task.detached {
            try ProbeProcessLock.acquire(
                filename: ProbeConstants.liveActivityLifecycleLockFilename
            )
        }.value
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
