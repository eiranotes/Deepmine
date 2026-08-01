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
    let feedback: GameFeedback
    let onFinished: (PlayerState) -> Void
    @State var player: PlayerState
    @State var isRequesting = false
    @State var struckWeakPoint = false
    @State var lastStrikeText: String?

    init(
        gameStore: GameStore,
        player: PlayerState,
        permissionCoordinator: any OnboardingPermissionCoordinating,
        feedback: GameFeedback,
        onFinished: @escaping (PlayerState) -> Void
    ) {
        self.gameStore = gameStore
        self.permissionCoordinator = permissionCoordinator
        self.feedback = feedback
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
                        case .premiseBlocks, .premiseSessions, .demo: demo
                        case .demoReward: reward
                        case .permissions: permission
                        case .complete: EmptyView()
                        }
                    }
                    .frame(minHeight: proxy.size.height, alignment: .top)
                    .padding(17)
                }
            }
        }
        .foregroundStyle(DeepMinePalette.limestone.color)
    }

    var demo: some View {
        VStack(spacing: 24) {
            VStack(spacing: 9) {
                Text(DeepMineStrings.text(.onboardingBlocksEyebrow))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                Text(DeepMineStrings.text(.onboardingDemoTitle))
                    .font(.title2.weight(.heavy))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("onboarding-demo-active")
                Text(DeepMineStrings.text(.onboardingDemoBody))
                    .font(.body)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            DeepMineRivetedPanel {
                VStack(spacing: 12) {
                    HStack {
                        Text("0m → 4m")
                            .font(.caption.monospacedDigit().weight(.bold))
                        Spacer()
                        Text("\(Int((player.mineFace.brokenFraction * 100).rounded()))%")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(DeepMinePalette.brass.color)
                    }
                    DeepMineProgressRail(
                        value: player.mineFace.brokenFraction,
                        total: 1,
                        accessibilityLabel: DeepMineStrings.text(.mineIntegrity)
                    )
                    demoShaft
                    Text(lastStrikeText ?? DeepMineStrings.text(.onboardingDemoActive))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 5) {
                Label(
                    DeepMineStrings.text(.onboardingSessionsTitle),
                    systemImage: "shippingbox.fill"
                )
                .font(.headline)
                .foregroundStyle(DeepMinePalette.brass.color)
                Text(DeepMineStrings.text(.onboardingSessionsBody))
                    .font(.subheadline)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var demoShaft: some View {
        let scene = ShaftSceneEngine.scene(for: player)
        let sceneHeight = ShaftGeometry.columnHeight(for: scene)
        return ZStack(alignment: .top) {
            DeepMinePalette.coal.color
            ShaftGeologyView(
                scene: scene,
                player: player,
                isStruck: struckWeakPoint,
                onStrike: strike(onWeakPoint:)
            )
            .frame(height: sceneHeight)
            .offset(y: 48)
            GeometryReader { proxy in
                GameArtView(
                    entry: GameArtCatalog.shaftSurface,
                    fill: CGSize(width: proxy.size.width, height: 48)
                )
            }
            .frame(height: 48)
            .allowsHitTesting(false)
        }
        .frame(height: min(210, sceneHeight + 48))
        .clipShape(RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                .stroke(DeepMinePalette.brass.color.opacity(0.72), lineWidth: 2)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DeepMineStrings.text(.onboardingDemoTitle))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("onboarding-demo-rock")
        .accessibilityAction { strike(onWeakPoint: false) }
    }
}
