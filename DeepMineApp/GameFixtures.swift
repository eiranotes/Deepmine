import DeepMineCore
import Foundation

enum GameSurface: String, CaseIterable, Sendable {
    case onboarding
    case mineHome
    case preflight
    case activeMine
    case returnReport
    case equipment
    case journal
    case statistics
    case themes
    case settings
    case prestige
    case activityCompact
    case activityMinimal
    case activityExpanded
    case lockScreen
    case standBy
    case widgetSmall
    case widgetMedium
    case controlCenter
    case diagnostics
}

enum GameFixtureScenario: String, CaseIterable, Sendable {
    case fresh
    case progressed
    case demoActive
    case demoCompleted
    case activeSealed
    case activeOpen
    case completed
    case abandoned
    case collapsed
    case blueVein
    case crystalVein
    case vaultVein
    case resonanceVein
    case abyssVein
    case emptyJournal
    case overflowStatistics
    case recovery
    case prestigeReady
    case passiveWaiting
    case passiveMining
    case passiveCompleted
    case passiveVein
    case passiveCollapsed
}

struct GameSessionFixture: Equatable, Sendable {
    let id: UUID
    let length: SessionLength
    let plan: MinePlan
    let verificationGrade: VerificationGrade
    let phase: SessionPhase
    let startedAt: Date
    let endsAt: Date
    let remainingSeconds: Int
}

struct GameReturnFixture: Equatable, Sendable {
    let completionID: UUID
    let length: SessionLength?
    let plan: MinePlan?
    let outcome: SessionOutcome
    let verificationGrade: VerificationGrade
    let focusedMinutes: Int
    let oreEarned: Double
    let vein: VeinKind?
    let depthMeters: Int
}

struct GameFixtureState: Equatable, Sendable {
    let scenario: GameFixtureScenario
    let surface: GameSurface
    let referenceDate: Date
    let player: PlayerState
    let session: GameSessionFixture?
    let report: GameReturnFixture?
    let status: DeepMineStatus
    let noticeKey: DeepMineStringKey?

    func shown(on surface: GameSurface) -> GameFixtureState {
        GameFixtureState(
            scenario: scenario,
            surface: surface,
            referenceDate: referenceDate,
            player: player,
            session: session,
            report: report,
            status: status,
            noticeKey: noticeKey
        )
    }
}

enum GameFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_774_963_200)

    static func fixture(for surface: GameSurface) -> GameFixtureState {
        let scenario: GameFixtureScenario
        switch surface {
        case .onboarding: scenario = .fresh
        case .preflight: scenario = .progressed
        case .activeMine, .activityCompact, .activityMinimal, .activityExpanded, .lockScreen, .standBy:
            scenario = .activeSealed
        case .returnReport: scenario = .completed
        case .journal: scenario = .emptyJournal
        case .statistics: scenario = .overflowStatistics
        case .prestige: scenario = .prestigeReady
        case .widgetSmall: scenario = .passiveWaiting
        case .widgetMedium: scenario = .passiveVein
        case .controlCenter: scenario = .passiveMining
        case .diagnostics: scenario = .recovery
        case .mineHome, .equipment, .themes, .settings: scenario = .progressed
        }
        return fixture(scenario).shown(on: surface)
    }

    static func fixture(_ scenario: GameFixtureScenario) -> GameFixtureState {
        switch scenario {
        case .fresh, .passiveWaiting:
            return state(scenario, player: PlayerState(), status: .notStarted)
        case .emptyJournal:
            return state(scenario, player: progressEmptyPlayer, status: .notStarted)
        case .progressed:
            return state(scenario, player: progressedPlayer, status: .completed)
        case .demoActive: return onboardingDemoActive
        case .demoCompleted: return onboardingDemoCompleted
        case .activeSealed, .passiveMining:
            return state(
                scenario,
                player: progressedPlayer,
                session: activeSession(grade: .sealed),
                status: .mining
            )
        case .activeOpen:
            return state(
                scenario,
                player: progressedPlayer,
                session: activeSession(grade: .open),
                status: .attention,
                noticeKey: .stateOpen
            )
        case .completed, .passiveCompleted:
            return completedState(scenario, grade: .sealed, vein: nil)
        case .passiveVein:
            return completedState(scenario, grade: .sealed, vein: .crystal)
        case .abandoned:
            return completedState(
                scenario,
                outcome: .abandoned(elapsedMinutes: 8),
                grade: .sealed,
                vein: nil,
                focusedMinutes: 8
            )
        case .collapsed, .passiveCollapsed:
            return completedState(
                scenario,
                outcome: .abandoned(elapsedMinutes: 5),
                grade: .collapsed,
                vein: nil,
                focusedMinutes: 5,
                plan: .deep
            )
        case .blueVein: return completedState(scenario, grade: .sealed, vein: .blue)
        case .crystalVein: return completedState(scenario, grade: .sealed, vein: .crystal)
        case .vaultVein: return completedState(scenario, grade: .sealed, vein: .vault)
        case .resonanceVein: return completedState(scenario, grade: .sealed, vein: .resonance)
        case .abyssVein: return completedState(scenario, grade: .sealed, vein: .abyss)
        case .overflowStatistics:
            return state(scenario, player: progressOverflowPlayer, status: .completed)
        case .recovery:
            return state(
                scenario,
                player: progressEmptyPlayer,
                status: .attention,
                noticeKey: .shellRecovery
            )
        case .prestigeReady:
            let player = PlayerState(
                resources: Resources(ore: 24_800, crystals: 8, coreShards: 2),
                equipment: EquipmentLevels(drill: 9, cart: 7, lamp: 6),
                runFocusCredits: Balance.initialPrestigeTarget,
                lifetimeFocusCredits: 64,
                completedSessionCount: 64,
                streakDays: 14
            )
            return state(scenario, player: player, status: .completed)
        }
    }
    static var allSurfaceFixtures: [GameFixtureState] {
        GameSurface.allCases.map(fixture(for:))
    }
    private static var progressedPlayer: PlayerState {
        PlayerState(
            resources: Resources(ore: 1_840, crystals: 4, coreShards: 0),
            equipment: EquipmentLevels(drill: 4, cart: 3, lamp: 2),
            runFocusCredits: 12,
            lifetimeFocusCredits: 12,
            completedSessionCount: 12,
            dailyGoalMinutes: Balance.defaultDailyGoalMinutes,
            streakDays: 7,
            consecutiveVeinMisses: 2,
            unlockedThemes: [.entry, .crystal],
            selectedTheme: .crystal,
            unlockedDecorations: [.marker, .rail]
        )
    }
    private static func activeSession(grade: VerificationGrade) -> GameSessionFixture {
        GameSessionFixture(
            id: uuid(10),
            length: .minutes25,
            plan: .safe,
            verificationGrade: grade,
            phase: .mining,
            startedAt: referenceDate,
            endsAt: referenceDate.addingTimeInterval(25 * 60),
            remainingSeconds: 17 * 60 + 30
        )
    }
    private static func completedState(
        _ scenario: GameFixtureScenario,
        outcome: SessionOutcome = .completed,
        grade: VerificationGrade,
        vein: VeinKind?,
        focusedMinutes: Int = 25,
        plan: MinePlan = .safe,
        length: SessionLength = .minutes25
    ) -> GameFixtureState {
        let player = progressedPlayer
        return state(
            scenario,
            player: player,
            report: GameReturnFixture(
                completionID: uuid(20 + scenarioIndex(scenario)),
                length: length,
                plan: plan,
                outcome: outcome,
                verificationGrade: grade,
                focusedMinutes: focusedMinutes,
                oreEarned: coreOre(
                    outcome: outcome,
                    length: length,
                    plan: plan,
                    grade: grade,
                    vein: vein,
                    player: player,
                    completionID: uuid(20 + scenarioIndex(scenario))
                ),
                vein: vein,
                depthMeters: 209
            ),
            status: grade == .collapsed ? .failed : .completed,
            noticeKey: grade == .collapsed ? .stateCollapsed : nil
        )
    }

    private static func state(
        _ scenario: GameFixtureScenario,
        player: PlayerState,
        session: GameSessionFixture? = nil,
        report: GameReturnFixture? = nil,
        status: DeepMineStatus,
        noticeKey: DeepMineStringKey? = nil
    ) -> GameFixtureState {
        GameFixtureState(
            scenario: scenario,
            surface: .mineHome,
            referenceDate: referenceDate,
            player: player,
            session: session,
            report: report,
            status: status,
            noticeKey: noticeKey
        )
    }

    private static func uuid(_ finalByte: Int) -> UUID {
        UUID(uuidString: String(format: "44454550-4D49-4E45-0000-%012d", finalByte))!
    }

    private static func scenarioIndex(_ scenario: GameFixtureScenario) -> Int {
        GameFixtureScenario.allCases.firstIndex(of: scenario) ?? 0
    }

}
