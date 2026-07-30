import DeepMineCore
import SwiftUI

enum SessionReadiness: String, Sendable {
    case sealed
    case open
    case noList
    case pending
    case failure

    var expectedGrade: VerificationGrade { self == .sealed ? .sealed : .open }

    var titleKey: DeepMineStringKey {
        switch self {
        case .sealed: .preflightSealed
        case .open: .preflightOpen
        case .noList: .preflightNoList
        case .pending: .preflightPending
        case .failure: .preflightFailure
        }
    }
}

@MainActor
protocol SessionReadinessProviding: AnyObject {
    func currentReadiness() -> SessionReadiness
}

@MainActor
final class FixedSessionReadinessProvider: SessionReadinessProviding {
    private let value: SessionReadiness
    init(_ value: SessionReadiness) { self.value = value }
    func currentReadiness() -> SessionReadiness { value }
}

@MainActor
struct SessionPreflightSheet: View {
    let gameStore: GameStore
    let length: SessionLength
    let plan: MinePlan
    let readiness: SessionReadiness
    let projection: SessionRewardProjection
    let onStarted: (PersistedGameSession) -> Void
    let onConfigure: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isPreparing = false
    @State private var startFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 17) {
                    promisePanel
                    rewardPanel
                    readinessPanel
                    consequencePanel
                    if isPreparing { preparingPanel }
                    startButton
                }
                .padding(17)
            }
            .background(DeepMinePalette.coal.color.ignoresSafeArea())
            .foregroundStyle(DeepMinePalette.limestone.color)
            .navigationTitle(DeepMineStrings.text(.preflightTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(DeepMineStrings.text(.actionCancel)) { dismiss() }
                        .disabled(isPreparing)
                }
            }
        }
        .tint(DeepMinePalette.brass.color)
        .alert(DeepMineStrings.text(.preflightStartFailed), isPresented: $startFailed) {
            Button(DeepMineStrings.text(.actionConfirm), role: .cancel) {}
        }
    }

    private var promisePanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label(planTitle, systemImage: "map.fill")
                    .font(.title3.weight(.heavy))
                    .accessibilityIdentifier("preflight-selection")
                HStack {
                    value(DeepMineStrings.text(.gamePlan), planTitle)
                    Spacer()
                    value(
                        DeepMineStrings.text(.gameDuration),
                        "\(length.minutes) \(DeepMineStrings.text(.gameMinutes))"
                    )
                }
            }
        }
    }

    private var rewardPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text(DeepMineStrings.text(.preflightRewardTitle))
                    .font(.headline)
                    .accessibilityIdentifier("preflight-reward-breakdown")
                HStack {
                    Text(DeepMineStrings.text(.gameExpectedReward))
                    Spacer()
                    Text(DeepMineNumberFormatter.string(projection.completedReward.ore))
                        .font(.title3.monospacedDigit().weight(.heavy))
                        .foregroundStyle(DeepMinePalette.brass.color)
                }
                rewardRow(
                    .preflightRewardBase,
                    value: projection.completedReward.breakdown.baseOre
                )
                rewardRow(
                    .preflightRewardMultipliers,
                    value: projection.completedReward.breakdown.combinedMultiplier,
                    prefix: "×"
                )
                // The survey shaft trades ore for this number. Without it the trade is
                // invisible and the plan reads as a strictly worse choice.
                HStack {
                    Text(DeepMineStrings.text(.preflightVeinChance))
                    Spacer()
                    Text(projection.veinChance.formatted(.percent.precision(.fractionLength(0...1))))
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.74))
                .accessibilityIdentifier("preflight-vein-chance")
            }
        }
    }

    private var readinessPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(DeepMineStrings.text(.gameVerification)).font(.headline)
                    Spacer()
                    DeepMineStatusMarker(status: readiness == .sealed ? .completed : .attention)
                }
                Text(DeepMineStrings.text(readiness.titleKey))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("preflight-readiness-\(readiness.rawValue)")
                if readiness != .sealed {
                    Label(
                        DeepMineStrings.text(.preflightOpenMultiplier),
                        systemImage: "door.left.hand.open"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    Button(action: onConfigure) {
                        Text(DeepMineStrings.text(.preflightConfigure))
                    }
                    .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                    .accessibilityIdentifier("preflight-configure")
                }
            }
        }
    }

    private var consequencePanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(DeepMineStrings.text(.gameConsequence))
                    .font(.headline)
                    .accessibilityIdentifier("preflight-abandon-consequence")
                Text(DeepMineStrings.text(
                    plan == .deep ? .preflightAbandonDeep : .preflightAbandonSafe
                ))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(DeepMineStrings.text(.preflightHalfwayExample))
                    Spacer()
                    Text(DeepMineNumberFormatter.string(projection.abandonmentReward.ore))
                        .font(.caption.monospacedDigit().weight(.bold))
                }
                .font(.caption)
            }
        }
    }

    private var preparingPanel: some View {
        HStack(spacing: 10) {
            ProgressView().tint(DeepMinePalette.brass.color)
            Text(DeepMineStrings.text(
                readiness == .sealed ? .preflightPreparing : .preflightPreparingOpen
            ))
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .accessibilityIdentifier("preflight-preparing")
    }

    private var startButton: some View {
        Button { Task { await start() } } label: {
            DeepMineActionLabel(titleKey: .actionStart, detailKey: .homeStartDetail, symbol: "hammer.fill")
        }
        .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
        .disabled(isPreparing)
        .accessibilityIdentifier("preflight-confirm-start")
    }

    private func value(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(DeepMinePalette.limestone.color.opacity(0.64))
            Text(detail).font(.subheadline.weight(.bold))
        }
    }

    private func rewardRow(
        _ key: DeepMineStringKey,
        value: Double,
        prefix: String = ""
    ) -> some View {
        HStack {
            Text(DeepMineStrings.text(key))
            Spacer()
            Text(prefix + value.formatted(.number.precision(.fractionLength(0...2))))
                .monospacedDigit()
        }
        .font(.caption)
        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.74))
    }

    private var planTitle: String {
        let key: DeepMineStringKey = switch plan {
        case .safe: .gameSafePlan
        case .deep: .gameDeepPlan
        case .survey: .gameSurveyPlan
        }
        return DeepMineStrings.text(key)
    }

    private func start() async {
        isPreparing = true
        do {
            try await gameStore.start(length: length, plan: plan)
            guard let session = gameStore.activeSession else {
                isPreparing = false
                startFailed = true
                return
            }
            onStarted(session)
            dismiss()
        } catch {
            isPreparing = false
            startFailed = true
        }
    }
}
