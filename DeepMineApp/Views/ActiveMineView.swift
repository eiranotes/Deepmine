import DeepMineCore
import SwiftUI

@MainActor
struct ActiveMineView: View {
    let gameStore: GameStore
    let onReturn: (GameReturnReport) -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: PersistedGameSession
    @State private var remainingSeconds: Int
    @State private var showingAbandon = false
    @State private var abandonmentProjection: SessionRewardProjection?
    @State private var actionFailed = false
    @State private var failureKey = DeepMineStringKey.activeRecoveryFailed
    @State private var currentGrade: VerificationGrade

    init(
        gameStore: GameStore,
        session: PersistedGameSession,
        onReturn: @escaping (GameReturnReport) -> Void
    ) {
        self.gameStore = gameStore
        self.onReturn = onReturn
        _session = State(initialValue: session)
        _remainingSeconds = State(initialValue: max(
            0, Int(ceil(session.endsAt.timeIntervalSince(gameStore.clock.wallNow())))
        ))
        _currentGrade = State(initialValue: gameStore.currentVerificationGrade(for: session))
    }

    var body: some View {
        ZStack {
            DeepMinePalette.coal.color.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 17) {
                    mineHeader
                    timerPanel
                    verificationPanel
                    quietPromise
                    abandonButton
                }
                .padding(17)
            }
        }
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.activeTitle))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task { await monitor() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await recover() } }
        }
        .alert(DeepMineStrings.text(.activeAbandonTitle), isPresented: $showingAbandon) {
            Button(DeepMineStrings.text(.activeAbandonCancel), role: .cancel) {}
            Button(DeepMineStrings.text(.activeAbandonConfirm), role: .destructive) {
                Task { await abandon() }
            }
        } message: {
            Text(abandonMessage)
        }
        .alert(DeepMineStrings.text(failureKey), isPresented: $actionFailed) {
            Button(DeepMineStrings.text(.actionConfirm), role: .cancel) {}
        }
    }

    private var mineHeader: some View {
        HStack(spacing: 14) {
            Image("MinerSprite")
                .resizable().interpolation(.none).scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(regionTitle)
                    .font(.title3.weight(.heavy))
                    .accessibilityIdentifier("active-mine-header")
                Text(planTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DeepMinePalette.brass.color)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var timerPanel: some View {
        DeepMineRivetedPanel {
            VStack(spacing: 14) {
                Text(timerText)
                    .font(.system(.largeTitle, design: .monospaced).weight(.heavy))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityLabel(timerAccessibility)
                    .accessibilityIdentifier("active-mine-timer")
                DeepMineProgressRail(
                    value: elapsedSeconds,
                    total: totalSeconds,
                    accessibilityLabel: DeepMineStrings.text(.stateMining)
                )
                Text("\(session.length.minutes) \(DeepMineStrings.text(.gameMinutes))")
                    .font(.caption.monospacedDigit())
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var verificationPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(DeepMineStrings.text(.gameVerification)).font(.headline)
                    Spacer()
                    DeepMineStatusMarker(status: verificationStatus)
                }
                if currentGrade != .sealed {
                    Text(verificationReason)
                        .font(.subheadline)
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityIdentifier("active-mine-\(currentGrade.rawValue)")
    }

    private var quietPromise: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The product wants the phone face down. Saying so is the point of this
            // screen; the countdown is only there to confirm the promise was taken.
            Label(DeepMineStrings.text(.activePutDown), systemImage: "iphone.slash")
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("active-mine-put-down")
            Label(DeepMineStrings.text(.activeQuietPromise), systemImage: "eye.slash.fill")
                .font(.caption)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("active-mine-quiet")
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private var abandonButton: some View {
        Button {
            abandonmentProjection = try? gameStore.activeRewardProjection()
            showingAbandon = true
        } label: {
            DeepMineActionLabel(titleKey: .actionAbandon, detailKey: .gameConsequence, symbol: "figure.walk.departure")
        }
        .buttonStyle(DeepMineMetalButtonStyle(role: .warning))
        .accessibilityIdentifier("active-mine-abandon")
    }

    private var timerText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private var timerAccessibility: String {
        "\(remainingSeconds / 60) \(DeepMineStrings.text(.gameMinutes)) "
            + "\(remainingSeconds % 60) \(DeepMineStrings.text(.gameSeconds))"
    }

    private var totalSeconds: Double {
        max(1, session.endsAt.timeIntervalSince(session.startedAt))
    }

    private var elapsedSeconds: Double {
        totalSeconds - Double(remainingSeconds)
    }

    private var verificationStatus: DeepMineStatus {
        switch currentGrade {
        case .sealed: .mining
        case .open: .attention
        case .collapsed: .failed
        }
    }

    private var verificationReason: String {
        switch currentGrade {
        case .sealed: ""
        case .open: session.openReason ?? DeepMineStrings.text(.activeOpenReason)
        case .collapsed: DeepMineStrings.text(.activeCollapsedReason)
        }
    }

    private var abandonMessage: String {
        if session.plan == .deep { return DeepMineStrings.text(.preflightAbandonDeep) }
        let ore = abandonmentProjection?.abandonmentReward.ore ?? 0
        return DeepMineStrings.text(.preflightAbandonSafe)
            + " \(DeepMineNumberFormatter.string(ore))"
    }

    private var planTitle: String {
        let key: DeepMineStringKey = switch session.plan {
        case .safe: .gameSafePlan
        case .deep: .gameDeepPlan
        case .survey: .gameSurveyPlan
        }
        return DeepMineStrings.text(key)
    }

    private var regionTitle: String {
        let region = WorldProgression.region(forDepth: (try? gameStore.playerState().depthMeters) ?? 0)
        let key: DeepMineStringKey = switch region {
        case .entry: .regionEntry
        case .crystal: .regionCrystal
        case .ruins: .regionRuins
        case .abyss: .regionAbyss
        }
        return DeepMineStrings.text(key)
    }

    private func monitor() async {
        await recover()
        while !Task.isCancelled, remainingSeconds > 0 {
            remainingSeconds = max(0, Int(ceil(session.endsAt.timeIntervalSince(gameStore.clock.wallNow()))))
            currentGrade = gameStore.currentVerificationGrade(for: session)
            if remainingSeconds == 0 {
                if let report = try? await gameStore.completeIfNeeded() { onReturn(report) }
                return
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func recover() async {
        do {
            try await gameStore.resume()
            if let active = gameStore.activeSession {
                session = active
                currentGrade = gameStore.currentVerificationGrade(for: active)
            }
            if let report = gameStore.returnReport, gameStore.activeSession == nil {
                onReturn(report)
            }
        } catch {
            failureKey = .activeRecoveryFailed
            actionFailed = true
        }
    }

    private func abandon() async {
        do {
            onReturn(try await gameStore.abandon())
        } catch {
            failureKey = .activeAbandonFailed
            actionFailed = true
        }
    }
}
