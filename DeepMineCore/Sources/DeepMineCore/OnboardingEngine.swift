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

public enum DemoStrikeResult: Equatable, Sendable {
    case struck(update: MineFaceUpdate)
    case rewarded(update: MineFaceUpdate, ore: Double, vein: VeinKind)
    case alreadyRewarded
}

public enum OnboardingEngine {
    /// The first interaction is the real clicker loop, not a shortened focus session.
    /// Existing pre-demo stages are accepted so saves from the prior two-page flow land
    /// on the same breakable rock instead of being stranded in removed screens.
    public static func strikeDemo<R: RandomNumberGenerator>(
        at date: Date,
        receiptID: UUID,
        hitWeakPoint: Bool = false,
        using generator: inout R,
        in state: inout PlayerState
    ) -> DemoStrikeResult {
        guard state.demoRewardReceiptID == nil else { return .alreadyRewarded }
        if state.demoStartedAt == nil { state.demoStartedAt = date }
        state.onboardingStage = .demo

        let update = MiningLoop.strike(
            hitWeakPoint: hitWeakPoint,
            using: &generator,
            in: &state
        )
        guard update.brokeSomething else { return .struck(update: update) }

        // The normal first rock pays four ore. Top the wallet up to one exact drill
        // upgrade so the tutorial teaches the real break path without changing the
        // established first-purchase contract.
        state.resources.ore = max(state.resources.ore, BigNumber(Balance.demoOreGrant))
        state.demoCompletedAt = date
        state.demoRewardReceiptID = receiptID
        state.onboardingStage = .demoReward
        // The first rock demonstrates the vein reveal, which is the moment the whole
        // loop is built around. Its crystal is granted so the reward screen has
        // something concrete to show.
        _ = WorldProgression.apply(
            vein: Balance.demoGuaranteedVein,
            effectID: receiptID,
            regionIndex: 0,
            to: &state
        )
        return .rewarded(
            update: update,
            ore: Balance.demoOreGrant,
            vein: Balance.demoGuaranteedVein
        )
    }

    public static func purchaseRecommendedUpgrade(
        commandID: UUID,
        in state: inout PlayerState
    ) -> UpgradePurchaseResult {
        guard state.demoRewardReceiptID != nil else {
            return .insufficientOre(
                required: Balance.drillBasePrice,
                available: state.resources.ore.doubleValue
            )
        }
        if state.demoUpgradePurchaseID != nil { return .duplicate }
        let result = EquipmentEngine.purchase(
            UpgradePurchaseCommand(id: commandID, equipment: .drill),
            in: &state
        )
        if case .purchased = result {
            state.demoUpgradePurchaseID = commandID
            // Permissions belong to the optional focus amplifier, not the gate into the
            // idle clicker. Settings and preflight keep the contextual request paths.
            state.onboardingStage = .complete
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
