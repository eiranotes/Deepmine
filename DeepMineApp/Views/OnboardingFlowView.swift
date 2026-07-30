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
    @State var player: PlayerState
    @State var remainingSeconds = Int(Balance.demoDurationSeconds)
    @State var isRequesting = false
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
    func premise(
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
    var demo: some View {
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
}
