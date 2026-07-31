import DeepMineCore
import SwiftUI
@MainActor
struct SettingsView: View {
    @Environment(\.scenePhase) var scenePhase
    let gameStore: GameStore?
    let player: PlayerState
    let system: any SettingsSystemCoordinating
    let feedback: GameFeedback
    let hasRecoveryNotice: Bool
    let savedGoalMinutes: Int?
    let onPlayerChange, onGoalSaved: (PlayerState) -> Void
    let onOpenThemes, onOpenPrestige, onOpenDiagnostics: () -> Void
    @State var goalMinutes: Int
    @State var snapshot: SettingsPermissionSnapshot?
    @State var isShowingBlockList = false
    @State var notice: DeepMineStringKey?
    @State var haptics: Bool
    @State var sound: Bool
    @State var versionTaps = 0
    @State var diagnosticsRevealed = false
    init(
        gameStore: GameStore?, player: PlayerState,
        system: any SettingsSystemCoordinating, feedback: GameFeedback,
        hasRecoveryNotice: Bool, savedGoalMinutes: Int?,
        onPlayerChange: @escaping (PlayerState) -> Void,
        onGoalSaved: @escaping (PlayerState) -> Void,
        onOpenThemes: @escaping () -> Void,
        onOpenPrestige: @escaping () -> Void,
        onOpenDiagnostics: @escaping () -> Void
    ) {
        self.gameStore = gameStore
        self.player = player
        self.system = system
        self.feedback = feedback
        self.hasRecoveryNotice = hasRecoveryNotice
        self.savedGoalMinutes = savedGoalMinutes
        self.onPlayerChange = onPlayerChange
        self.onGoalSaved = onGoalSaved
        self.onOpenThemes = onOpenThemes
        self.onOpenPrestige = onOpenPrestige
        self.onOpenDiagnostics = onOpenDiagnostics
        _goalMinutes = State(initialValue: player.dailyGoalMinutes)
        _haptics = State(initialValue: feedback.hapticsEnabled)
        _sound = State(initialValue: feedback.soundEnabled)
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                if hasRecoveryNotice { recoveryPanel }
                destinationPanel
                restPanel
                permissionPanel
                feedbackPanel
                aboutPanel
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationSettings))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("settings-screen")
        .task { await refreshSnapshot() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshSnapshot() }
        }
        .sheet(isPresented: $isShowingBlockList) {
            system.blockListPicker(
                onSaved: {
                    notice = .settingsBlockListSaved
                    Task { await refreshSnapshot() }
                },
                onFailure: { notice = .settingsBlockListFailed }
            )
        }
    }
    private var destinationPanel: some View {
        DeepMineRivetedPanel {
            VStack(spacing: 12) {
                routeButton(.navigationThemes, symbol: "paintbrush", id: "settings-open-themes", action: onOpenThemes)
                routeButton(.navigationPrestige, symbol: "arrow.down.to.line.compact", id: "settings-open-prestige", action: onOpenPrestige)
            }
        }
    }
    private var restPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label(DeepMineStrings.text(.gameRestDay), systemImage: "moon.zzz")
                    .font(.headline)
                Text(DeepMineStrings.text(.settingsRestBody))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("settings-rest-policy")
    }
    private var permissionPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label(DeepMineStrings.text(.gamePermissions), systemImage: "door.left.hand.closed")
                    .font(.headline)
                if let snapshot {
                    permissionRow(.focusProtection, state: snapshot.focus)
                    permissionRow(.endAlert, state: snapshot.endAlert)
                    permissionRow(.returnReminder, state: snapshot.returnReminder)
                    Button { isShowingBlockList = true } label: {
                        DeepMineActionLabel(titleKey: .gameBlockList, detailKey: .settingsBlockListBody, symbol: "app.badge")
                    }
                    .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                    .accessibilityIdentifier("settings-block-list-open")
                    if snapshot.focus == .ready {
                        Text("\(DeepMineStrings.text(.stateSealed)) · \(snapshot.selectedApplications + snapshot.selectedCategories)")
                            .font(.caption)
                            .accessibilityIdentifier("settings-block-list-ready")
                    }
                } else {
                    ProgressView().tint(DeepMinePalette.brass.color)
                }
                if let notice, [.settingsBlockListSaved, .settingsBlockListFailed,
                                .settingsPermissionSaveFailed].contains(notice) {
                    Text(DeepMineStrings.text(notice)).font(.caption)
                }
            }
        }
    }
    private var feedbackPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text(DeepMineStrings.text(.settingsFeedbackBody)).font(.subheadline)
                Toggle(isOn: Binding(
                    get: { haptics },
                    set: { enabled in setHaptics(enabled) }
                )) {
                    Label(DeepMineStrings.text(.gameHaptics), systemImage: "iphone.radiowaves.left.and.right")
                }
                .toggleStyle(.switch)
                .accessibilityIdentifier("settings-haptics-toggle")
                Toggle(isOn: Binding(
                    get: { sound },
                    set: { enabled in setSound(enabled) }
                )) {
                    Label(DeepMineStrings.text(.gameSound), systemImage: "speaker.wave.2")
                }
                .toggleStyle(.switch)
                .accessibilityIdentifier("settings-sound-toggle")
            }
        }
    }
    private var recoveryPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label(DeepMineStrings.text(.settingsRecoveryTitle), systemImage: "checkmark.shield")
                    .font(.headline)
                    .foregroundStyle(DeepMinePalette.brass.color)
                Text(DeepMineStrings.text(.settingsRecoveryBody)).font(.subheadline)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("settings-recovery-notice")
    }
    private var aboutPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text(DeepMineStrings.text(.settingsAboutTitle)).font(.headline)
                Text(DeepMineStrings.text(.settingsPrivacyBody)).font(.subheadline)
                Button { registerVersionTap() } label: {
                    Text("\(DeepMineStrings.text(.settingsVersion)) 1.0")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings-version")
                if diagnosticsRevealed {
                    Button(action: onOpenDiagnostics) {
                        DeepMineActionLabel(titleKey: .navigationDiagnostics, detailKey: nil, symbol: "wrench.and.screwdriver")
                    }
                    .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                    .accessibilityIdentifier("settings-open-diagnostics")
                }
            }
        }
    }
}
