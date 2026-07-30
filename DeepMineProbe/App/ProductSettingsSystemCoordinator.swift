@preconcurrency import FamilyControls
import AlarmKit
import DeepMineCore
import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class ProductSettingsSystemCoordinator: SettingsSystemCoordinating {
    private let screenTime: ScreenTimeProbe
    private let notificationCenter = UNUserNotificationCenter.current()

    init(screenTime: ScreenTimeProbe) { self.screenTime = screenTime }

    func request(_ kind: OnboardingPermissionKind) async -> OnboardingPermissionOutcome {
        do {
            switch kind {
            case .focusProtection:
                return Self.isFocusAuthorized(try await screenTime.requestAuthorization())
                    ? .granted : .denied
            case .endAlert:
                let manager = AlarmManager.shared
                let state = manager.authorizationState == .notDetermined
                    ? try await manager.requestAuthorization()
                    : manager.authorizationState
                return state == .authorized ? .granted : .denied
            case .returnReminder:
                return try await notificationCenter.requestAuthorization(options: [.alert, .sound])
                    ? .granted : .denied
            }
        } catch {
            return .denied
        }
    }

    func currentSnapshot(player _: PlayerState) async -> SettingsPermissionSnapshot {
        let applicationCount = screenTime.selection.applicationTokens.count
        let categoryCount = screenTime.selection.categoryTokens.count
        let focusAuthorization = AuthorizationCenter.shared.authorizationStatus
        let focus: SettingsPermissionState
        if Self.isFocusAuthorized(focusAuthorization) {
            focus = applicationCount + categoryCount > 0 ? .ready : .needsSelection
        } else {
            focus = focusAuthorization == .notDetermined ? .notAsked : .denied
        }
        let endAlert: SettingsPermissionState = switch AlarmManager.shared.authorizationState {
        case .authorized: .ready
        case .notDetermined: .notAsked
        case .denied: .denied
        @unknown default: .unavailable
        }
        let notification = await notificationCenter.notificationSettings()
        let reminder: SettingsPermissionState = switch notification.authorizationStatus {
        case .authorized, .provisional, .ephemeral: .ready
        case .notDetermined: .notAsked
        case .denied: .denied
        @unknown default: .unavailable
        }
        return SettingsPermissionSnapshot(
            focus: focus,
            endAlert: endAlert,
            returnReminder: reminder,
            selectedApplications: applicationCount,
            selectedCategories: categoryCount
        )
    }

    func repair(_ kind: OnboardingPermissionKind) async -> OnboardingPermissionOutcome {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return .denied }
        return await UIApplication.shared.open(url) ? .deferred : .denied
    }

    func blockListPicker(
        onSaved: @escaping @MainActor () -> Void,
        onFailure: @escaping @MainActor () -> Void
    ) -> AnyView {
        AnyView(SettingsBlockListPicker(
            screenTime: screenTime,
            onSaved: onSaved,
            onFailure: onFailure
        ))
    }

    private static func isFocusAuthorized(_ status: AuthorizationStatus) -> Bool {
        if status == .approved { return true }
        if #available(iOS 26.4, *) { return status == .approvedWithDataAccess }
        return false
    }
}

@MainActor
final class DeterministicSettingsSystemCoordinator: SettingsSystemCoordinating {
    private var snapshot: SettingsPermissionSnapshot
    private let deniedKind: OnboardingPermissionKind?

    init(
        snapshot: SettingsPermissionSnapshot = .ready,
        deniedKind: OnboardingPermissionKind? = nil
    ) {
        self.snapshot = snapshot
        self.deniedKind = deniedKind
    }

    func request(_ kind: OnboardingPermissionKind) async -> OnboardingPermissionOutcome {
        if kind == deniedKind { return .denied }
        switch kind {
        case .focusProtection:
            snapshot = SettingsPermissionSnapshot(
                focus: .ready,
                endAlert: snapshot.endAlert,
                returnReminder: snapshot.returnReminder,
                selectedApplications: max(1, snapshot.selectedApplications),
                selectedCategories: snapshot.selectedCategories
            )
        case .endAlert:
            snapshot = replacing(endAlert: .ready)
        case .returnReminder:
            snapshot = replacing(returnReminder: .ready)
        }
        return .granted
    }

    func currentSnapshot(player _: PlayerState) async -> SettingsPermissionSnapshot { snapshot }

    func repair(_ kind: OnboardingPermissionKind) async -> OnboardingPermissionOutcome {
        await request(kind)
    }

    func blockListPicker(
        onSaved: @escaping @MainActor () -> Void,
        onFailure _: @escaping @MainActor () -> Void
    ) -> AnyView {
        AnyView(DeterministicBlockListPicker {
            self.snapshot = SettingsPermissionSnapshot(
                focus: .ready,
                endAlert: self.snapshot.endAlert,
                returnReminder: self.snapshot.returnReminder,
                selectedApplications: 2,
                selectedCategories: 1
            )
            onSaved()
        })
    }

    private func replacing(
        endAlert: SettingsPermissionState? = nil,
        returnReminder: SettingsPermissionState? = nil
    ) -> SettingsPermissionSnapshot {
        SettingsPermissionSnapshot(
            focus: snapshot.focus,
            endAlert: endAlert ?? snapshot.endAlert,
            returnReminder: returnReminder ?? snapshot.returnReminder,
            selectedApplications: snapshot.selectedApplications,
            selectedCategories: snapshot.selectedCategories
        )
    }
}

private struct SettingsBlockListPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: FamilyActivitySelection
    @State private var saveFailed = false
    let screenTime: ScreenTimeProbe
    let onSaved: @MainActor () -> Void
    let onFailure: @MainActor () -> Void

    init(
        screenTime: ScreenTimeProbe,
        onSaved: @escaping @MainActor () -> Void,
        onFailure: @escaping @MainActor () -> Void
    ) {
        self.screenTime = screenTime
        self.onSaved = onSaved
        self.onFailure = onFailure
        _draft = State(initialValue: screenTime.selection)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                if saveFailed {
                    Text(DeepMineStrings.text(.settingsBlockListFailed))
                        .font(.caption)
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .padding(.horizontal, 17)
                        .accessibilityIdentifier("settings-block-list-error")
                }
                FamilyActivityPicker(selection: $draft)
            }
                .navigationTitle(DeepMineStrings.text(.gameBlockList))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(DeepMineStrings.text(.actionCancel)) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(DeepMineStrings.text(.actionSave)) { save() }
                            .accessibilityIdentifier("settings-block-list-save")
                    }
                }
        }
    }

    private func save() {
        do {
            try screenTime.replaceSelection(draft)
            onSaved()
            dismiss()
        } catch {
            saveFailed = true
            onFailure()
        }
    }
}

private struct DeterministicBlockListPicker: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 17) {
                Text(DeepMineStrings.text(.settingsBlockListBody))
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    onSave()
                    dismiss()
                } label: {
                    DeepMineActionLabel(titleKey: .actionSave, detailKey: nil, symbol: "tray.and.arrow.down")
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
                .accessibilityIdentifier("settings-block-list-save")
            }
            .padding(17)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DeepMinePalette.coal.color.ignoresSafeArea())
            .foregroundStyle(DeepMinePalette.limestone.color)
        }
    }
}
