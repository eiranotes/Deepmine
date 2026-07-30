import Foundation

public enum OnboardingStage: String, Codable, CaseIterable, Sendable {
    case premiseBlocks
    case premiseSessions
    case demo
    case demoReward
    case permissions
    case complete
}

public enum OnboardingPermissionKind: String, Codable, CaseIterable, Sendable {
    case focusProtection
    case endAlert
    case returnReminder
}

public enum OnboardingPermissionOutcome: String, Codable, CaseIterable, Sendable {
    case notAsked
    case granted
    case denied
    case deferred
}

public enum DemoBeginResult: Equatable, Sendable {
    case started(endsAt: Date)
    case resumed(endsAt: Date)
    case alreadyCompleted
}

public enum DemoCompletionResult: Equatable, Sendable {
    case tooEarly(remainingSeconds: Int)
    case rewarded(ore: Double, vein: VeinKind)
    case alreadyRewarded
}

public enum OnboardingEngine {
    public static func advancePremise(in state: inout PlayerState) {
        switch state.onboardingStage {
        case .premiseBlocks: state.onboardingStage = .premiseSessions
        case .premiseSessions: state.onboardingStage = .demo
        default: break
        }
    }

    public static func beginDemo(at date: Date, in state: inout PlayerState) -> DemoBeginResult {
        guard state.demoRewardReceiptID == nil else { return .alreadyCompleted }
        if let startedAt = state.demoStartedAt {
            return .resumed(endsAt: startedAt.addingTimeInterval(Balance.demoDurationSeconds))
        }
        state.demoStartedAt = date
        state.onboardingStage = .demo
        return .started(endsAt: date.addingTimeInterval(Balance.demoDurationSeconds))
    }

    public static func completeDemo(
        at date: Date,
        receiptID: UUID,
        in state: inout PlayerState
    ) -> DemoCompletionResult {
        guard state.demoRewardReceiptID == nil else { return .alreadyRewarded }
        guard let startedAt = state.demoStartedAt else {
            return .tooEarly(remainingSeconds: Int(Balance.demoDurationSeconds))
        }
        let remaining = startedAt.addingTimeInterval(Balance.demoDurationSeconds)
            .timeIntervalSince(date)
        guard remaining <= 0 else {
            return .tooEarly(remainingSeconds: Int(ceil(remaining)))
        }
        state.resources.ore += Balance.demoOreGrant
        state.demoCompletedAt = date
        state.demoRewardReceiptID = receiptID
        state.onboardingStage = .demoReward
        // The practice return demonstrates the vein reveal, which is the moment the
        // whole loop is built around. Its crystal is granted so the reward screen has
        // something concrete to show.
        _ = WorldProgression.apply(
            vein: Balance.demoGuaranteedVein,
            effectID: receiptID,
            regionIndex: 0,
            to: &state
        )
        return .rewarded(ore: Balance.demoOreGrant, vein: Balance.demoGuaranteedVein)
    }

    public static func purchaseRecommendedUpgrade(
        commandID: UUID,
        in state: inout PlayerState
    ) -> UpgradePurchaseResult {
        guard state.demoRewardReceiptID != nil else {
            return .insufficientOre(
                required: Balance.drillBasePrice,
                available: state.resources.ore
            )
        }
        if state.demoUpgradePurchaseID != nil { return .duplicate }
        let result = EquipmentEngine.purchase(
            UpgradePurchaseCommand(id: commandID, equipment: .drill),
            in: &state
        )
        if case .purchased = result {
            state.demoUpgradePurchaseID = commandID
            state.onboardingStage = .permissions
        }
        return result
    }

    public static func recordPermission(
        _ kind: OnboardingPermissionKind,
        outcome: OnboardingPermissionOutcome,
        in state: inout PlayerState
    ) {
        switch kind {
        case .focusProtection: state.focusProtectionPermission = outcome
        case .endAlert: state.endAlertPermission = outcome
        case .returnReminder: state.returnReminderPermission = outcome
        }
    }

    public static func finish(in state: inout PlayerState) {
        state.onboardingStage = .complete
    }

    public static func select(plan: MinePlan, in state: inout PlayerState) {
        guard plan != .deep || state.isDeepMiningUnlocked else { return }
        state.lastSelectedPlan = plan
    }

    public static func select(duration: SessionLength, in state: inout PlayerState) {
        state.lastSelectedDuration = duration
    }
}
