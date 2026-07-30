import DeepMineCore
import SwiftUI

/// Controls and save paths behind the settings panels.
@MainActor
extension SettingsView {
    func routeButton(_ key: DeepMineStringKey, symbol: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { DeepMineActionLabel(titleKey: key, detailKey: nil, symbol: symbol) }
            .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            .accessibilityIdentifier(id)
    }
    func compactGoalButton(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).font(.subheadline.monospacedDigit().weight(.bold)).frame(minWidth: 34, minHeight: 44) }
            .buttonStyle(.borderless)
            .foregroundStyle(DeepMinePalette.limestone.color)
            .accessibilityIdentifier(id)
    }
    func permissionRow(_ kind: OnboardingPermissionKind, state: SettingsPermissionState) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(DeepMineStrings.text(kind.settingsTitleKey)).font(.subheadline.weight(.semibold))
                Spacer()
                Text(DeepMineStrings.text(state.settingsKey)).font(.caption.weight(.bold))
                    .foregroundStyle(state == .ready ? DeepMinePalette.limestone.color : DeepMinePalette.brass.color)
                    .accessibilityIdentifier("settings-permission-\(kind.settingsID)-\(state.settingsID)")
            }
            if state != .ready {
                Button {
                    if kind == .focusProtection, state == .needsSelection {
                        isShowingBlockList = true
                    } else { Task { await resolve(kind, state: state) } }
                } label: {
                    DeepMineActionLabel(
                        titleKey: state == .needsSelection ? .gameBlockList
                            : state == .denied || state == .unavailable
                                ? .actionSystemSettings : .actionRetry,
                        detailKey: nil,
                        symbol: state == .needsSelection ? "app.badge"
                            : state == .denied || state == .unavailable
                                ? "gearshape" : "arrow.clockwise"
                    )
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                .accessibilityIdentifier(state == .needsSelection
                    ? "settings-permission-\(kind.settingsID)-choose-list"
                    : "settings-permission-\(kind.settingsID)-retry")
            }
        }
    }
    func saveGoal() {
        guard let gameStore else { notice = .progressStorageBody; return }
        do {
            onGoalSaved(try gameStore.configureDailyGoal(minutes: goalMinutes))
        } catch { notice = .progressStorageBody }
    }
    func request(_ kind: OnboardingPermissionKind) async {
        let outcome = await system.request(kind)
        persistPermission(kind, outcome: outcome)
        await refreshSnapshot()
    }
    func resolve(_ kind: OnboardingPermissionKind, state: SettingsPermissionState) async {
        guard state == .denied || state == .unavailable else {
            await request(kind)
            return
        }
        let outcome = await system.repair(kind)
        persistPermission(kind, outcome: outcome)
        await refreshSnapshot()
    }
    func persistPermission(_ kind: OnboardingPermissionKind,
                                   outcome: OnboardingPermissionOutcome) {
        guard let gameStore else { return }
        do { onPlayerChange(try gameStore.recordPermission(kind, outcome: outcome)) }
        catch { notice = .settingsPermissionSaveFailed }
    }
    func refreshSnapshot() async { snapshot = await system.currentSnapshot(player: player) }
    func setHaptics(_ enabled: Bool) {
        haptics = enabled
        feedback.hapticsEnabled = enabled
    }

    func setSound(_ enabled: Bool) {
        sound = enabled
        feedback.soundEnabled = enabled
    }

    func registerVersionTap() {
        versionTaps += 1
        diagnosticsRevealed = versionTaps >= 7
    }
}
