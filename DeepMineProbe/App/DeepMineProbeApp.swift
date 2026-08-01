@preconcurrency import FamilyControls
import DeepMineCore
import SwiftData
import SwiftUI

@main
struct DeepMineApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let repository: GameRepository?
    private let gameStore: GameStore?
    private let settingsCoordinator: any SettingsSystemCoordinating
    private let readinessProvider: any SessionReadinessProviding
    private let hasRecoveryNotice: Bool
    private let fixtureName: String?
    private let activitySurfaceName: String?
    private let widgetSurfaceName: String?
    private let commandRunner: GameCommandRunner?
    @State private var launchNotice: String?
    @State private var isShowingLaunchNotice: Bool

    init() {
        let environment = ProcessInfo.processInfo.environment
        fixtureName = environment["DEEPMINE_UI_FIXTURE"]
        activitySurfaceName = environment["DEEPMINE_ACTIVITY_SURFACE"]
        widgetSurfaceName = environment["DEEPMINE_WIDGET_SURFACE"]
        let notice: String?
        let settings: any SettingsSystemCoordinating
        var selectedReadiness = SessionReadiness.failure
        var selectedProvider: any SessionReadinessProviding = FixedSessionReadinessProvider(.failure)
        do {
            let repository = try Self.repository(for: environment)
            let screenTime = ScreenTimeProbe()
            if let raw = environment["DEEPMINE_UI_READINESS"],
               let fixtureReadiness = SessionReadiness(rawValue: raw) {
                selectedReadiness = fixtureReadiness
                selectedProvider = FixedSessionReadinessProvider(fixtureReadiness)
            } else {
                selectedReadiness = .pending
                selectedProvider = ProductSessionReadinessProvider(screenTime: screenTime)
            }
            if environment["DEEPMINE_UI_RESET"] == "1" {
                try GameFixtures.seedActiveSessionIfNeeded(
                    named: environment["DEEPMINE_UI_FIXTURE"] ?? "",
                    repository: repository
                )
                try GameFixtures.seedReturnReportIfNeeded(
                    named: environment["DEEPMINE_UI_FIXTURE"],
                    repository: repository
                )
            }
            self.repository = repository
            let system: any SessionSystemCoordinating = environment["DEEPMINE_UI_FIXTURE"] == nil
                ? SessionSystemCoordinator(screenTime: screenTime)
                : DeterministicSessionSystemCoordinator(readiness: selectedReadiness)
            let sessionRepository: any GameSessionRepository
            switch fixtureName {
            case "progress-recovery":
                sessionRepository = RecoveringProgressRepository(base: repository)
            case "equipment-retry-ambiguous":
                sessionRepository = AmbiguousPurchaseProgressRepository(base: repository)
            default:
                sessionRepository = repository
            }
            if GameFixtures.isProgressFixture(fixtureName) {
                gameStore = GameStore(
                    repository: sessionRepository,
                    coordinator: system,
                    clock: DeterministicProgressClock(date: GameFixtures.referenceDate),
                    calendar: GameFixtures.progressCalendar,
                    timeZone: GameFixtures.progressTimeZone
                )
            } else {
                gameStore = GameStore(repository: sessionRepository, coordinator: system)
            }
            settings = environment["DEEPMINE_UI_PERMISSION"] == nil
                ? ProductSettingsSystemCoordinator(screenTime: screenTime)
                : DeterministicSettingsSystemCoordinator(
                    snapshot: GameFixtures.settingsSnapshot(named: fixtureName),
                    deniedKind: Self.permissionKind(environment["DEEPMINE_UI_PERMISSION"])
                )
            notice = repository.recoveryNotice == nil
                ? nil
                : DeepMineStrings.text(.noticeStorageRecovered)
        } catch let error as GamePersistenceError {
            repository = nil
            gameStore = nil
            settings = DeterministicSettingsSystemCoordinator()
            notice = Self.message(for: error)
        } catch {
            repository = nil
            gameStore = nil
            settings = DeterministicSettingsSystemCoordinator()
            notice = DeepMineStrings.text(.noticeStorageOpenFailed)
        }
        settingsCoordinator = settings
        readinessProvider = selectedProvider
        hasRecoveryNotice = GameFixtures.hasRecoveryNotice(named: fixtureName) || notice != nil
        _launchNotice = State(initialValue: notice)
        _isShowingLaunchNotice = State(initialValue: notice != nil)
        if fixtureName == nil, let repository, let gameStore {
            let runner = GameCommandRunner(repository: repository, gameStore: gameStore)
            commandRunner = runner
            // Registered even before the scene appears, so a Dynamic Island tap that
            // launches this process in the background still applies its command.
            MainActor.assumeIsolated { GameSurfaceCommandRunner.register(runner) }
        } else {
            commandRunner = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
        Group {
            if ProcessInfo.processInfo.environment["DEEPMINE_SCREENSHOT_SECTION"] != nil {
                if let repository {
                    ProbeDashboardView().modelContainer(repository.modelContainer)
                } else {
                    ProbeDashboardView()
                }
            } else if let widgetSurfaceName {
                GameWidgetSurfaceFixtureView(
                    stateName: fixtureName ?? "widget-waiting",
                    surfaceName: widgetSurfaceName
                )
            } else if let activitySurfaceName {
                GameActivitySurfaceFixtureView(
                    stateName: fixtureName ?? "surface-mining",
                    surfaceName: activitySurfaceName
                )
            } else if let repository, let gameStore {
                GameRootView(
                    repository: repository,
                    gameStore: gameStore,
                    settingsCoordinator: settingsCoordinator,
                    readinessProvider: readinessProvider,
                    hasRecoveryNotice: hasRecoveryNotice
                )
                    .modelContainer(repository.modelContainer)
            } else {
                GameRootView(fixture: GameFixtures.fixture(.recovery))
            }
        }
        .alert(DeepMineStrings.text(.noticeStorageTitle), isPresented: $isShowingLaunchNotice) {
            Button(DeepMineStrings.text(.actionConfirm), role: .cancel) {}
        } message: {
            Text(launchNotice ?? "")
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                Task { await drainPendingCommands() }
            }
        }
    }

    @MainActor
    private func drainPendingCommands() async {
        // UI fixtures use isolated stores and deterministic coordinators. They must not
        // consume the product App Group queue left by another process or test run.
        guard fixtureName == nil, let commandRunner else { return }
        await commandRunner.runPendingCommands()
        if commandRunner.lastFailed {
            launchNotice = DeepMineStrings.text(.noticeCommandRetry)
            isShowingLaunchNotice = true
        }
    }

    private static func message(for error: GamePersistenceError) -> String {
        switch error {
        case .unsupportedSchemaVersion:
            DeepMineStrings.text(.noticeStorageNewerData)
        case .appGroupUnavailable:
            DeepMineStrings.text(.noticeStorageSharedUnavailable)
        case .missingEntity, .invalidStoredValue:
            DeepMineStrings.text(.noticeStorageInvalid)
        }
    }

    private static func repository(for environment: [String: String]) throws -> GameRepository {
        guard let storeID = environment["DEEPMINE_UI_STORE_ID"] else {
            return try GameRepository.openShared()
        }
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "DeepMineUITests")
            .appending(path: storeID)
        if environment["DEEPMINE_UI_RESET"] == "1" {
            try? FileManager.default.removeItem(at: directory)
        }
        let repository = try GameRepository.open(storeURL: directory.appending(path: "DeepMine.store"))
        if environment["DEEPMINE_UI_RESET"] == "1" {
            try repository.save(playerFixture(environment["DEEPMINE_UI_FIXTURE"]))
        }
        return repository
    }

    private static func playerFixture(_ name: String?) -> PlayerState {
        switch name {
        case "demo-active":
            return PlayerState(onboardingStage: .demo, demoStartedAt: Date())
        case "demo-completed":
            return GameFixtures.onboardingDemoCompleted.player
        case "permissions":
            return GameFixtures.onboardingLegacyPermissionsPlayer
        case "home-fresh":
            return GameFixtures.returningPlayer()
        case "home-progressed":
            return GameFixtures.returningPlayer(completedSessions: 2)
        case "home-unlocked":
            return GameFixtures.returningPlayer(completedSessions: 3)
        case let name? where GameFixtures.progressPlayer(named: name) != nil:
            return GameFixtures.progressPlayer(named: name)!
        case let name? where GameFixtures.settingsPlayer(named: name) != nil:
            return GameFixtures.settingsPlayer(named: name)!
        case let name? where GameFixtures.sessionPlayer(for: name) != nil:
            return GameFixtures.sessionPlayer(for: name)!
        case let name? where GameFixtures.returnSeed(named: name) != nil:
            return GameFixtures.returnSeed(named: name)!.player
        default:
            return PlayerState()
        }
    }

}

@MainActor
private final class ProductSessionReadinessProvider: SessionReadinessProviding {
    private let screenTime: ScreenTimeProbe

    init(screenTime: ScreenTimeProbe) { self.screenTime = screenTime }

    func currentReadiness() -> SessionReadiness {
        let status = AuthorizationCenter.shared.authorizationStatus
        var authorized = status == .approved
        if #available(iOS 26.4, *) {
            authorized = authorized || status == .approvedWithDataAccess
        }
        if authorized {
            let hasList = !screenTime.selection.applicationTokens.isEmpty
                || !screenTime.selection.categoryTokens.isEmpty
            return hasList ? .sealed : .noList
        }
        return status == .notDetermined ? .pending : .open
    }
}

private extension DeepMineApp {
    static func permissionKind(_ value: String?) -> OnboardingPermissionKind? {
        switch value {
        case "deny-focus": .focusProtection
        case "deny-end": .endAlert
        case "deny-return": .returnReminder
        default: nil
        }
    }
}
