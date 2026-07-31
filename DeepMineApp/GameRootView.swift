import DeepMineCore
import SwiftUI

enum GameRoute: Hashable {
    case activeMine, returnReport, equipment(ReturnUpgradeRecommendation?)
    case statistics, achievements
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
    @State var offlineSettlement: OfflineSettlement?
    @Environment(\.scenePhase) private var scenePhase

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
                        mineFace: clickerSection,
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
        .sheet(item: $offlineSettlement) { settlement in
            OfflineReturnSheet(settlement: settlement) { offlineSettlement = nil }
        }
        .task { await recoverSession() }
        .task { settleOfflineProduction() }
        .onChange(of: scenePhase) { _, phase in
            // Returning from the background is the same event as launching, as far as
            // the mine is concerned: time passed and it was working.
            if phase == .active { settleOfflineProduction() }
        }
        .onChange(of: player) { _, _ in refreshRecommendation() }
    }

    /// Pays out the time the app was closed, and offers the result if it is worth
    /// interrupting for. Fixtures are excluded so screen tests stay deterministic.
    func settleOfflineProduction() {
        guard showsClickerRoot, let repository else { return }
        var updated = player
        let settlement = MiningLoop.settleOffline(
            since: updated.lastSettledAt,
            now: Date(),
            in: &updated
        )
        player = updated
        try? repository.save(updated)
        if settlement.isWorthReporting {
            offlineSettlement = settlement
            feedback.play(.sessionCompleted)
        }
    }

    var shouldShowOnboarding: Bool {
        !forceHome && player.onboardingStage != .complete
    }

    /// Fixtures render deterministic screens for capture tests, so the live mine — which
    /// mutates on a timer — is excluded from them.
    var showsClickerRoot: Bool {
        fixtureState == nil
    }

    @ViewBuilder
    var clickerSectionView: some View {
        MineFaceView(
            player: $player,
            feedback: feedback,
            onPersist: persistMineFace
        )
    }

    var clickerSection: AnyView? {
        showsClickerRoot ? AnyView(clickerSectionView) : nil
    }

    /// The clicker mutates the player on a timer, and writing every tick would be a
    /// write per quarter second. Persisting only when a segment actually breaks keeps
    /// the cost proportional to progress rather than to time.
    func persistMineFace(_ updated: PlayerState) {
        try? repository?.save(updated)
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
