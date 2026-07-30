import DeepMineCore
import SwiftUI

/// The practice reward, permission and hand-off steps.
@MainActor
extension OnboardingFlowView {
    var reward: some View {
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
                    // The practice return always finds a vein, so the first thing a new
                    // player sees includes the mechanic the loop is built around.
                    Label(
                        DeepMineStrings.text(
                            DeepMineProgressLabels.veinKey(Balance.demoGuaranteedVein)
                        ),
                        systemImage: "sparkles"
                    )
                    .font(.headline)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("onboarding-demo-vein")
                    Text(DeepMineStrings.text(.onboardingDemoVeinBody))
                        .font(.subheadline)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.74))
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
    var permission: some View {
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

    var timerText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var timerAccessibilityLabel: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        let minutePart = minutes > 0
            ? "\(minutes) \(DeepMineStrings.text(.gameMinutes))"
            : ""
        return [minutePart, "\(seconds) \(DeepMineStrings.text(.gameSeconds))"]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var nextPermission: OnboardingPermissionKind {
        if player.focusProtectionPermission == .notAsked { return .focusProtection }
        if player.endAlertPermission == .notAsked { return .endAlert }
        return .returnReminder
    }

    func advancePremise() {
        if let updated = try? gameStore.advanceOnboardingPremise() { player = updated }
    }

    func startDemo() {
        guard let state = try? gameStore.beginOrResumeDemo() else { return }
        remainingSeconds = state.remainingSeconds
        player = (try? gameStore.playerState()) ?? player
    }

    func monitorDemoIfNeeded() async {
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

    func installUpgrade() {
        _ = try? gameStore.purchaseDemoUpgrade()
        player = (try? gameStore.playerState()) ?? player
    }

    func request(_ kind: OnboardingPermissionKind) async {
        isRequesting = true
        let outcome = await permissionCoordinator.request(kind)
        isRequesting = false
        record(kind, outcome: outcome)
    }

    func deferPermission(_ kind: OnboardingPermissionKind) {
        record(kind, outcome: .deferred)
    }

    func record(_ kind: OnboardingPermissionKind, outcome: OnboardingPermissionOutcome) {
        guard let updated = try? gameStore.recordPermission(kind, outcome: outcome) else { return }
        player = updated
        if updated.returnReminderPermission != .notAsked,
           let completed = try? gameStore.finishOnboarding() {
            player = completed
            onFinished(completed)
        }
    }

    func permissionTitle(_ kind: OnboardingPermissionKind) -> DeepMineStringKey {
        switch kind {
        case .focusProtection: .onboardingPermissionFocusTitle
        case .endAlert: .onboardingPermissionEndTitle
        case .returnReminder: .onboardingPermissionReturnTitle
        }
    }

    func permissionBody(_ kind: OnboardingPermissionKind) -> DeepMineStringKey {
        switch kind {
        case .focusProtection: .onboardingPermissionFocusBody
        case .endAlert: .onboardingPermissionEndBody
        case .returnReminder: .onboardingPermissionReturnBody
        }
    }

    func permissionSymbol(_ kind: OnboardingPermissionKind) -> String {
        switch kind {
        case .focusProtection: "door.left.hand.closed"
        case .endAlert: "bell.and.waves.left.and.right.fill"
        case .returnReminder: "note.text"
        }
    }
}
