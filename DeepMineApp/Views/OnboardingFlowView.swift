import DeepMineCore
import SwiftUI
@MainActor
protocol OnboardingPermissionCoordinating: AnyObject {
    func request(_ kind: OnboardingPermissionKind) async -> OnboardingPermissionOutcome
}
@MainActor
struct OnboardingFlowView: View {
    let gameStore: GameStore
    let permissionCoordinator: any OnboardingPermissionCoordinating
    let onFinished: (PlayerState) -> Void
    @State private var player: PlayerState
    @State private var remainingSeconds = Int(Balance.demoDurationSeconds)
    @State private var isRequesting = false
    init(
        gameStore: GameStore,
        player: PlayerState,
        permissionCoordinator: any OnboardingPermissionCoordinating,
        onFinished: @escaping (PlayerState) -> Void
    ) {
        self.gameStore = gameStore
        self.permissionCoordinator = permissionCoordinator
        self.onFinished = onFinished
        _player = State(initialValue: player)
    }
    var body: some View {
        ZStack {
            DeepMinePalette.coal.color.ignoresSafeArea()
            GeometryReader { proxy in
                ScrollView {
                    Group {
                        switch player.onboardingStage {
                        case .premiseBlocks:
                            premise(
                                eyebrow: .onboardingBlocksEyebrow,
                                title: .onboardingBlocksTitle,
                                body: .onboardingBlocksBody,
                                symbol: "door.left.hand.closed",
                                identifier: "onboarding-premise-blocks"
                            )
                        case .premiseSessions:
                            premise(
                                eyebrow: .onboardingSessionsEyebrow,
                                title: .onboardingSessionsTitle,
                                body: .onboardingSessionsBody,
                                symbol: "arrow.down.to.line.compact",
                                identifier: "onboarding-premise-sessions"
                            )
                        case .demo: demo
                        case .demoReward: reward
                        case .permissions: permission
                        case .complete: EmptyView()
                        }
                    }
                    .frame(minHeight: proxy.size.height)
                    .padding(17)
                }
            }
        }
        .foregroundStyle(DeepMinePalette.limestone.color)
        .task(id: player.demoStartedAt) { await monitorDemoIfNeeded() }
    }
    private func premise(
        eyebrow: DeepMineStringKey,
        title: DeepMineStringKey,
        body: DeepMineStringKey,
        symbol: String,
        identifier: String
    ) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(DeepMinePalette.brass.color)
                .frame(width: 88, height: 88)
                .background(DeepMinePalette.shale.color, in: RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)
            VStack(spacing: 9) {
                Text(DeepMineStrings.text(eyebrow))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                Text(DeepMineStrings.text(title))
                    .font(.title2.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(identifier)
                Text(DeepMineStrings.text(body))
                    .font(.body)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button { advancePremise() } label: {
                DeepMineActionLabel(titleKey: .actionNext, detailKey: nil, symbol: "arrow.right")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
            .accessibilityIdentifier("onboarding-next")
        }
    }
    private var demo: some View {
        VStack(spacing: 17) {
            Spacer()
            DeepMineRivetedPanel {
                VStack(spacing: 15) {
                    Image("MinerSprite")
                        .resizable().interpolation(.none).scaledToFit()
                        .frame(width: 96, height: 96)
                        .accessibilityHidden(true)
                    Text(DeepMineStrings.text(.onboardingDemoTitle))
                        .font(.title2.weight(.heavy))
                        .accessibilityIdentifier("onboarding-demo-active")
                    Text(DeepMineStrings.text(.onboardingDemoBody))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                    DeepMineStatusMarker(status: player.demoStartedAt == nil ? .notStarted : .mining)
                    if player.demoStartedAt != nil {
                        Text(timerText)
                            .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                            .foregroundStyle(DeepMinePalette.brass.color)
                            .accessibilityLabel(timerAccessibilityLabel)
                            .accessibilityIdentifier("onboarding-demo-timer")
                        Text(DeepMineStrings.text(.onboardingDemoActive))
                            .font(.caption)
                            .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
            if player.demoStartedAt == nil {
                Button { startDemo() } label: {
                    DeepMineActionLabel(titleKey: .actionStart, detailKey: .onboardingDemoActive, symbol: "hammer.fill")
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
                .accessibilityIdentifier("onboarding-demo-start")
            }
        }
    }
    private var reward: some View {
        VStack(spacing: 17) {
            Spacer()
            DeepMineRivetedPanel {
                VStack(spacing: 14) {
                    DeepMineStatusMarker(status: .completed)
                    Text(DeepMineStrings.text(.onboardingDemoRewardTitle))
                        .font(.title2.weight(.heavy))
                        .accessibilityIdentifier("onboarding-demo-reward")
                    Text(DeepMineStrings.text(.onboardingDemoRewardBody))
                        .multilineTextAlignment(.center)
                    Divider().overlay(DeepMinePalette.limestone.color.opacity(0.25))
                    Label(DeepMineStrings.text(.onboardingUpgradeTitle), systemImage: "gearshape.2.fill")
                        .font(.headline)
                    Text(DeepMineStrings.text(.onboardingUpgradeBody))
                        .font(.subheadline)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.74))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
            Button { installUpgrade() } label: {
                DeepMineActionLabel(titleKey: .actionInstallUpgrade, detailKey: .onboardingUpgradeTitle, symbol: "wrench.and.screwdriver.fill")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
            .accessibilityIdentifier("onboarding-demo-upgrade")
        }
    }
    private var permission: some View {
        let kind = nextPermission
        return VStack(spacing: 17) {
            Spacer()
            DeepMineRivetedPanel {
                VStack(spacing: 14) {
                    Image(systemName: permissionSymbol(kind))
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                    Text(DeepMineStrings.text(permissionTitle(kind)))
                        .font(.title3.weight(.heavy))
                        .accessibilityIdentifier("onboarding-permission-\(kind.rawValue)")
                    Text(DeepMineStrings.text(permissionBody(kind)))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                    Text(DeepMineStrings.text(.onboardingPermissionOpen))
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.64))
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
            Button { Task { await request(kind) } } label: {
                DeepMineActionLabel(titleKey: .actionEnable, detailKey: nil, symbol: "checkmark")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
            .disabled(isRequesting)
            .accessibilityIdentifier("onboarding-permission-allow")
            Button { deferPermission(kind) } label: {
                Text(DeepMineStrings.text(.actionNotNow))
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            .accessibilityIdentifier("onboarding-permission-defer")
        }
    }

    private var timerText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private var timerAccessibilityLabel: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        let minutePart = minutes > 0
            ? "\(minutes) \(DeepMineStrings.text(.gameMinutes))"
            : ""
        return [minutePart, "\(seconds) \(DeepMineStrings.text(.gameSeconds))"]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private var nextPermission: OnboardingPermissionKind {
        if player.focusProtectionPermission == .notAsked { return .focusProtection }
        if player.endAlertPermission == .notAsked { return .endAlert }
        return .returnReminder
    }

    private func advancePremise() {
        if let updated = try? gameStore.advanceOnboardingPremise() { player = updated }
    }

    private func startDemo() {
        guard let state = try? gameStore.beginOrResumeDemo() else { return }
        remainingSeconds = state.remainingSeconds
        player = (try? gameStore.playerState()) ?? player
    }

    private func monitorDemoIfNeeded() async {
        guard player.onboardingStage == .demo, player.demoStartedAt != nil else { return }
        while !Task.isCancelled {
            guard let state = try? gameStore.demoState() else { return }
            remainingSeconds = state.remainingSeconds
            if state.remainingSeconds == 0 {
                _ = try? gameStore.completeDemoIfNeeded()
                player = (try? gameStore.playerState()) ?? player
                return
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func installUpgrade() {
        _ = try? gameStore.purchaseDemoUpgrade()
        player = (try? gameStore.playerState()) ?? player
    }

    private func request(_ kind: OnboardingPermissionKind) async {
        isRequesting = true
        let outcome = await permissionCoordinator.request(kind)
        isRequesting = false
        record(kind, outcome: outcome)
    }

    private func deferPermission(_ kind: OnboardingPermissionKind) {
        record(kind, outcome: .deferred)
    }

    private func record(_ kind: OnboardingPermissionKind, outcome: OnboardingPermissionOutcome) {
        guard let updated = try? gameStore.recordPermission(kind, outcome: outcome) else { return }
        player = updated
        if updated.returnReminderPermission != .notAsked,
           let completed = try? gameStore.finishOnboarding() {
            player = completed
            onFinished(completed)
        }
    }

    private func permissionTitle(_ kind: OnboardingPermissionKind) -> DeepMineStringKey {
        switch kind {
        case .focusProtection: .onboardingPermissionFocusTitle
        case .endAlert: .onboardingPermissionEndTitle
        case .returnReminder: .onboardingPermissionReturnTitle
        }
    }

    private func permissionBody(_ kind: OnboardingPermissionKind) -> DeepMineStringKey {
        switch kind {
        case .focusProtection: .onboardingPermissionFocusBody
        case .endAlert: .onboardingPermissionEndBody
        case .returnReminder: .onboardingPermissionReturnBody
        }
    }

    private func permissionSymbol(_ kind: OnboardingPermissionKind) -> String {
        switch kind {
        case .focusProtection: "door.left.hand.closed"
        case .endAlert: "bell.and.waves.left.and.right.fill"
        case .returnReminder: "note.text"
        }
    }
}
