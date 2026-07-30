import DeepMineCore
import SwiftUI

enum GameRoute: Hashable {
    case activeMine, returnReport, equipment(ReturnUpgradeRecommendation?)
    case journal, statistics, achievements
    case themes, settings, prestige, diagnostics
}

@MainActor
struct GameRootView: View {
    let repository: GameRepository?
    let gameStore: GameStore?
    let settingsCoordinator: any SettingsSystemCoordinating
    let hasRecoveryNotice: Bool
    let forceHome: Bool
    let fixtureState: GameFixtureState?
    let readinessProvider: any SessionReadinessProviding
    let feedback: GameFeedback
    @State var player: PlayerState
    @State var path: [GameRoute] = []
    @State var showingPreflight = false
    @State var savedGoalMinutes: Int?
    @State var homeRecommendation: UpgradeRecommendation?
    @State var homeProjectedOre: Double?

    init(
        repository: GameRepository,
        gameStore: GameStore,
        settingsCoordinator: any SettingsSystemCoordinating,
        readinessProvider: any SessionReadinessProviding,
        hasRecoveryNotice: Bool
    ) {
        self.repository = repository
        self.gameStore = gameStore
        self.settingsCoordinator = settingsCoordinator
        self.readinessProvider = readinessProvider
        self.hasRecoveryNotice = hasRecoveryNotice
        let environment = ProcessInfo.processInfo.environment
        let feedback = GameFeedback(scope: environment["DEEPMINE_UI_STORE_ID"] ?? "product")
        if environment["DEEPMINE_UI_RESET"] == "1" { feedback.resetUITestReceipts() }
        if environment["DEEPMINE_UI_RESET"] == "1",
           environment["DEEPMINE_UI_FIXTURE"] == "settings-feedback-off" {
            feedback.configureUITestPreferences(haptics: false, sound: false)
        }
        self.feedback = feedback
        forceHome = false
        fixtureState = nil
        let player = (try? repository.load()) ?? PlayerState()
        _player = State(initialValue: player)
        _savedGoalMinutes = State(initialValue: nil)
    }

    init(fixture: GameFixtureState) {
        repository = nil
        gameStore = nil
        settingsCoordinator = DeterministicSettingsSystemCoordinator()
        hasRecoveryNotice = fixture.noticeKey != nil
        forceHome = true
        fixtureState = fixture
        readinessProvider = FixedSessionReadinessProvider(.pending)
        feedback = GameFeedback()
        _player = State(initialValue: fixture.player)
        _savedGoalMinutes = State(initialValue: nil)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if shouldShowOnboarding,
                   let gameStore {
                    OnboardingFlowView(
                        gameStore: gameStore,
                        player: player,
                        permissionCoordinator: settingsCoordinator
                    ) { completed in
                        player = completed
                    }
                } else {
                    MineHomeView(
                        player: player,
                        recommendation: homeRecommendation,
                        projectedOrePerSession: homeProjectedOre,
                        onSelectPlan: select(plan:),
                        onSelectDuration: select(duration:),
                        onStart: { showingPreflight = true },
                        onUpgrade: purchase(equipment:),
                        onOpenSettings: openSettings,
                        progressContext: ProgressNavigationContext(
                            gameStore: gameStore, player: player,
                            referenceDate: progressReferenceDate,
                            calendar: progressCalendar, timeZone: progressTimeZone,
                            onPlayerChange: { player = $0 }
                        )
                    )
                }
            }
            .navigationDestination(for: GameRoute.self, destination: destination)
        }
        .tint(DeepMinePalette.brass.color)
        .sheet(isPresented: $showingPreflight) { preflightSheet }
        .task { await recoverSession() }
        .onChange(of: player) { _, _ in refreshRecommendation() }
    }

    var shouldShowOnboarding: Bool {
        !forceHome && player.onboardingStage != .complete
    }

    @ViewBuilder
    func destination(for route: GameRoute) -> some View {
        switch route {
        case .activeMine:
            if let gameStore, let session = gameStore.activeSession {
                ActiveMineView(gameStore: gameStore, session: session, onReturn: receive)
            }
        case .returnReport:
            if let gameStore, let report = gameStore.returnReport {
                switch gameStore.returnPresentationState(for: report) {
                case let .ready(presentation):
                    ReturnReportView(
                        presentation: presentation,
                        feedback: feedback,
                        onFinish: { closeReport(report) },
                        onPrepareNext: { prepareNext($0, report: report) }
                    )
                case .failed:
                    returnReportRecovery
                }
            }
        case let .equipment(recommendation):
            EquipmentView(
                gameStore: gameStore,
                player: player,
                handoffRecommendation: recommendation,
                onPlayerChange: { player = $0 }
            )
        case .journal:
            JournalView(
                gameStore: gameStore,
                player: player,
                referenceDate: progressReferenceDate,
                calendar: progressCalendar,
                timeZone: progressTimeZone
            )
        case .statistics:
            StatisticsView(
                gameStore: gameStore,
                player: player,
                referenceDate: progressReferenceDate,
                calendar: progressCalendar,
                timeZone: progressTimeZone
            )
        case .achievements:
            AchievementsView(player: player)
        case .themes:
            ThemeView(
                gameStore: gameStore, player: player,
                onPlayerChange: { player = $0 }
            )
        case .settings:
            SettingsView(
                gameStore: gameStore, player: player,
                system: settingsCoordinator, feedback: feedback,
                hasRecoveryNotice: hasRecoveryNotice,
                savedGoalMinutes: savedGoalMinutes,
                onPlayerChange: { player = $0 },
                onGoalSaved: {
                    player = $0
                    savedGoalMinutes = $0.dailyGoalMinutes
                },
                onOpenThemes: { path.append(.themes) },
                onOpenPrestige: { path.append(.prestige) },
                onOpenDiagnostics: { path.append(.diagnostics) }
            )
        case .prestige:
            PrestigeView(
                gameStore: gameStore, player: player,
                onPlayerChange: { player = $0 },
                onFinish: { path = [] }
            )
        case .diagnostics:
            if let repository {
                ProbeDashboardView().modelContainer(repository.modelContainer)
            } else {
                ProbeDashboardView()
            }
        }
    }

    @ViewBuilder
    var preflightSheet: some View {
        let readiness = readinessProvider.currentReadiness()
        if let gameStore,
           let projection = try? gameStore.rewardProjection(
               length: player.lastSelectedDuration,
               plan: player.lastSelectedPlan,
               grade: readiness.expectedGrade
           ) {
            SessionPreflightSheet(
                gameStore: gameStore,
                length: player.lastSelectedDuration,
                plan: player.lastSelectedPlan,
                readiness: readiness,
                projection: projection,
                feedback: feedback,
                onStarted: { session in
                    showingPreflight = false
                    path.append(.activeMine)
                },
                onConfigure: {
                    showingPreflight = false
                    Task { @MainActor in
                        await Task.yield()
                        openSettings()
                    }
                }
            )
        }
    }
}
