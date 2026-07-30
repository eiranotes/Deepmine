import DeepMineCore
import Foundation

enum GameSurfacePhase: String, Codable, CaseIterable, Hashable, Sendable {
    case waiting
    case mining
    case completed
    case vein
    case collapsed
}

struct GameSurfaceUpgradeRecommendation: Codable, Hashable, Sendable {
    let equipmentID: String
    let currentLevel: Int
    let nextLevel: Int
    let cost: Double
    let marginalExpectedOre: Double
}

struct GameSurfaceSnapshot: Codable, Hashable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let phase: GameSurfacePhase
    let sessionID: String?
    let outcomeID: String?
    let planID: String
    let regionID: String
    let depthMeters: Int
    let expectedOre: Double
    let earnedOre: Double
    let streakDays: Int
    let timerStartedAt: TimeInterval?
    let timerEndsAt: TimeInterval?
    let verificationGradeID: String?
    let veinID: String?
    let upgradeRecommendation: GameSurfaceUpgradeRecommendation?
    let todayFocusedMinutes: Int
    let todayGoalMinutes: Int
    let generatedAt: TimeInterval
    let staleAfter: TimeInterval

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        phase: GameSurfacePhase,
        sessionID: String?,
        outcomeID: String? = nil,
        planID: String,
        regionID: String,
        depthMeters: Int,
        expectedOre: Double,
        earnedOre: Double,
        streakDays: Int,
        timerStartedAt: TimeInterval?,
        timerEndsAt: TimeInterval?,
        verificationGradeID: String?,
        veinID: String?,
        upgradeRecommendation: GameSurfaceUpgradeRecommendation?,
        todayFocusedMinutes: Int,
        todayGoalMinutes: Int,
        generatedAt: TimeInterval,
        staleAfter: TimeInterval
    ) {
        self.schemaVersion = schemaVersion
        self.phase = phase
        self.sessionID = sessionID
        self.outcomeID = outcomeID
        self.planID = planID
        self.regionID = regionID
        self.depthMeters = depthMeters
        self.expectedOre = expectedOre
        self.earnedOre = earnedOre
        self.streakDays = streakDays
        self.timerStartedAt = timerStartedAt
        self.timerEndsAt = timerEndsAt
        self.verificationGradeID = verificationGradeID
        self.veinID = veinID
        self.upgradeRecommendation = upgradeRecommendation
        self.todayFocusedMinutes = todayFocusedMinutes
        self.todayGoalMinutes = todayGoalMinutes
        self.generatedAt = generatedAt
        self.staleAfter = staleAfter
    }

    func isStale(at date: Date) -> Bool {
        date.timeIntervalSince1970 >= staleAfter
    }

    func activityPhase(isStale: Bool) -> GameSurfacePhase {
        phase == .mining && isStale ? .waiting : phase
    }
}

enum GameSurfaceSnapshotReadResult: Equatable, Sendable {
    case missing
    case fresh(GameSurfaceSnapshot)
    case stale(GameSurfaceSnapshot)
}

enum GameSurfaceSnapshotStoreError: Error, Equatable {
    case missingAppGroup(String)
    case payloadTooLarge(actual: Int, limit: Int)
    case unsupportedSchema(Int)
}

struct GameSurfaceSnapshotStore: Sendable {
    static let snapshotFilename = "GameSurfaceSnapshot.json"
    static let lockFilename = "GameSurfaceSnapshot.lock"
    static let maximumPayloadBytes = Balance.activityContentMaximumBytes

    let directoryURL: URL

    static func shared(fileManager: FileManager = .default) throws -> Self {
        guard let directory = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: ProbeConstants.appGroupIdentifier
        ) else {
            throw GameSurfaceSnapshotStoreError.missingAppGroup(
                ProbeConstants.appGroupIdentifier
            )
        }
        return Self(directoryURL: directory)
    }

    func read(at date: Date = Date()) throws -> GameSurfaceSnapshotReadResult {
        let lock = try ProbeProcessLock.acquire(
            filename: Self.lockFilename,
            directoryURL: directoryURL
        )
        defer { lock.release() }
        let url = directoryURL.appending(path: Self.snapshotFilename)
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        let data = try Data(contentsOf: url)
        guard data.count < Self.maximumPayloadBytes else {
            throw GameSurfaceSnapshotStoreError.payloadTooLarge(
                actual: data.count,
                limit: Self.maximumPayloadBytes
            )
        }
        let snapshot = try JSONDecoder().decode(GameSurfaceSnapshot.self, from: data)
        guard snapshot.schemaVersion == GameSurfaceSnapshot.currentSchemaVersion else {
            throw GameSurfaceSnapshotStoreError.unsupportedSchema(snapshot.schemaVersion)
        }
        return snapshot.isStale(at: date) ? .stale(snapshot) : .fresh(snapshot)
    }
}
