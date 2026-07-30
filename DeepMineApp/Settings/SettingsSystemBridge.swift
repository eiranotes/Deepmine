import DeepMineCore
import SwiftUI

enum SettingsPermissionState: Equatable, Sendable {
    case ready
    case needsSelection
    case notAsked
    case denied
    case unavailable
}

extension SettingsPermissionState {
    var settingsKey: DeepMineStringKey {
        switch self {
        case .ready: .settingsPermissionReady
        case .needsSelection: .settingsPermissionNeedsSelection
        case .notAsked: .settingsPermissionNotAsked
        case .denied: .settingsPermissionDenied
        case .unavailable: .settingsPermissionUnavailable
        }
    }
    var settingsID: String {
        switch self {
        case .ready: "ready"
        case .needsSelection: "needs-selection"
        case .notAsked: "not-asked"
        case .denied: "denied"
        case .unavailable: "unavailable"
        }
    }
}

extension OnboardingPermissionKind {
    var settingsTitleKey: DeepMineStringKey {
        switch self {
        case .focusProtection: .onboardingPermissionFocusTitle
        case .endAlert: .onboardingPermissionEndTitle
        case .returnReminder: .onboardingPermissionReturnTitle
        }
    }
    var settingsID: String {
        switch self {
        case .focusProtection: "focus"
        case .endAlert: "end"
        case .returnReminder: "return"
        }
    }
}

struct SettingsPermissionSnapshot: Equatable, Sendable {
    let focus: SettingsPermissionState
    let endAlert: SettingsPermissionState
    let returnReminder: SettingsPermissionState
    let selectedApplications: Int
    let selectedCategories: Int

    static let ready = SettingsPermissionSnapshot(
        focus: .ready,
        endAlert: .ready,
        returnReminder: .ready,
        selectedApplications: 2,
        selectedCategories: 1
    )
}

@MainActor
protocol SettingsSystemCoordinating: OnboardingPermissionCoordinating {
    func currentSnapshot(player: PlayerState) async -> SettingsPermissionSnapshot
    func repair(_ kind: OnboardingPermissionKind) async -> OnboardingPermissionOutcome
    func blockListPicker(
        onSaved: @escaping @MainActor () -> Void,
        onFailure: @escaping @MainActor () -> Void
    ) -> AnyView
}
