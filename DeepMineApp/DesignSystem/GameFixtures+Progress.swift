import DeepMineCore
import Foundation

struct DeterministicProgressClock: ClockSource {
    let date: Date

    func wallNow() -> Date { date }
    func continuousNanoseconds() -> UInt64 { 7_290_000_000_000 }
}

enum ProgressFixtureStorageError: Error { case unavailableOnce, ambiguousCommit }

@MainActor
class DelegatingProgressRepository: GameSessionRepository {
    let base: any GameSessionRepository
    init(base: any GameSessionRepository) { self.base = base }
    func loadPlayer() throws -> PlayerState { try base.loadPlayer() }
    func savePlayer(_ player: PlayerState) throws { try base.savePlayer(player) }
    func loadActiveSession() throws -> PersistedGameSession? { try base.loadActiveSession() }
    func loadReturnReport() throws -> GameReturnReport? { try base.loadReturnReport() }
    func clearReturnReport() throws { try base.clearReturnReport() }
    func saveActiveSession(_ session: PersistedGameSession, commandID: UUID?) throws {
        try base.saveActiveSession(session, commandID: commandID)
    }
    func markCommandApplied(_ commandID: UUID) throws { try base.markCommandApplied(commandID) }
    func commitSession(
        player: PlayerState,
        report: GameReturnReport,
        cleanupSession: PersistedGameSession
    ) throws {
        try base.commitSession(player: player, report: report, cleanupSession: cleanupSession)
    }
    func finishSessionCleanup(report: GameReturnReport) throws {
        try base.finishSessionCleanup(report: report)
    }
}

@MainActor
final class RecoveringProgressRepository: DelegatingProgressRepository {
    private var remainingPlayerLoadFailures = 2
    override func loadPlayer() throws -> PlayerState {
        if remainingPlayerLoadFailures > 0 {
            remainingPlayerLoadFailures -= 1
            throw ProgressFixtureStorageError.unavailableOnce
        }
        return try super.loadPlayer()
    }
}

@MainActor
final class AmbiguousPurchaseProgressRepository: DelegatingProgressRepository {
    private var shouldFailPlayerSave = true
    override func savePlayer(_ player: PlayerState) throws {
        try super.savePlayer(player)
        if shouldFailPlayerSave {
            shouldFailPlayerSave = false
            throw ProgressFixtureStorageError.ambiguousCommit
        }
    }
}

extension GameFixtures {
    static let progressTimeZone = TimeZone(secondsFromGMT: 0)!

    static var progressCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = progressTimeZone
        return calendar
    }

    static func isProgressFixture(_ name: String?) -> Bool {
        guard let name else { return false }
        return name.hasPrefix("progress-") || name.hasPrefix("equipment-")
    }

    static func progressPlayer(named name: String?) -> PlayerState? {
        switch name {
        case "progress-empty": progressEmptyPlayer
        case "progress-populated": progressPopulatedPlayer
        case "progress-overflow": progressOverflowPlayer
        case "progress-recovery": progressEmptyPlayer
        case "equipment-success": equipmentPlayer(ore: 500)
        case "equipment-retry-ambiguous": equipmentPlayer(ore: 500)
        case "equipment-insufficient": equipmentPlayer(ore: 0)
        // Depth has to reach the ceiling too, otherwise the row shows the depth lock
        // instead of the true maximum.
        case "equipment-maximum": equipmentPlayer(
            ore: .greatestFiniteMagnitude,
            equipment: EquipmentLevels(
                drill: 200,
                cart: 200,
                lamp: 200
            ),
            lifetimeFocusCredits: 200
        )
        default: nil
        }
    }

    static var progressEmptyPlayer: PlayerState {
        PlayerState(onboardingStage: .complete)
    }

    static var progressPopulatedPlayer: PlayerState {
        PlayerState(
            resources: Resources(ore: 1_840, crystals: 4),
            equipment: EquipmentLevels(drill: 4, cart: 3, lamp: 2),
            runFocusCredits: 12,
            lifetimeFocusCredits: 12,
            completedSessionCount: 5,
            history: history(count: 6),
            streakDays: 4,
            onboardingStage: .complete,
            lastSelectedPlan: .safe,
            lastSelectedDuration: .minutes25
        )
    }

    static var progressOverflowPlayer: PlayerState {
        PlayerState(
            resources: Resources(ore: 9_876_543_210, crystals: 240, coreShards: 12),
            equipment: EquipmentLevels(drill: 40, cart: 40, lamp: 40),
            runFocusCredits: 500,
            lifetimeFocusCredits: 500,
            completedSessionCount: 500,
            history: history(count: 500),
            streakDays: 30,
            unlockedThemes: Set(MineTheme.allCases),
            selectedTheme: .abyss,
            onboardingStage: .complete,
            // 15,000m of broken rock. Depth is no longer derived from focus credits
            // (D-040), so the statistics screen's deepest-ever reading has to come from
            // the mine face.
            mineFace: MineFaceState(segmentIndex: 3_750)
        )
    }

    private static func equipmentPlayer(
        ore: Double,
        equipment: EquipmentLevels = EquipmentLevels(),
        lifetimeFocusCredits: Double = 0
    ) -> PlayerState {
        PlayerState(
            resources: Resources(ore: BigNumber(ore)),
            equipment: equipment,
            lifetimeFocusCredits: lifetimeFocusCredits,
            completedSessionCount: 3,
            onboardingStage: .complete,
            // Equipment tiers are gated on depth, and depth comes from broken rock now
            // (D-040). Without a mine face this fixture is a surface player, so every
            // upgrade renders locked and the screen under test never appears.
            mineFace: MineFaceState(segmentIndex: 400)
        )
    }

    private static func history(count: Int) -> [SessionHistoryEntry] {
        return (0..<count).map { index in
            let completed = index % 7 != 0
            return SessionHistoryEntry(
                completionID: progressUUID(index),
                endedAt: referenceDate.addingTimeInterval(-TimeInterval((index + 1) * 240)),
                focusedMinutes: completed ? [15, 25, 50][index % 3] : 8,
                focusCredits: completed ? 1 : 0,
                plan: MinePlan.allCases[index % MinePlan.allCases.count],
                verificationGrade: completed ? .sealed : .open,
                oreEarned: completed ? Double(80 + index) : Double(index % 4),
                vein: index % 5 == 0 ? VeinKind.allCases[index % VeinKind.allCases.count] : nil,
                depthAfter: 110 + index * 3,
                completed: completed
            )
        }
    }

    private static func progressUUID(_ value: Int) -> UUID {
        UUID(uuidString: String(
            format: "44454550-4D49-4E45-1000-%012d",
            value
        ))!
    }
}
