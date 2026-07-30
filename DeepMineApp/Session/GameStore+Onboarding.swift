import DeepMineCore
import Foundation

struct DemoMiningState: Equatable, Sendable {
    let startedAt: Date
    let endsAt: Date
    let remainingSeconds: Int
    let isRewarded: Bool
}

@MainActor
extension GameStore {
    func playerState() throws -> PlayerState {
        try repository.loadPlayer()
    }

    func advanceOnboardingPremise() throws -> PlayerState {
        var player = try repository.loadPlayer()
        OnboardingEngine.advancePremise(in: &player)
        try repository.savePlayer(player)
        return player
    }

    func beginOrResumeDemo() throws -> DemoMiningState {
        var player = try repository.loadPlayer()
        _ = OnboardingEngine.beginDemo(at: clock.wallNow(), in: &player)
        try repository.savePlayer(player)
        return demoState(for: player)
    }

    func demoState() throws -> DemoMiningState? {
        let player = try repository.loadPlayer()
        guard player.demoStartedAt != nil else { return nil }
        return demoState(for: player)
    }

    @discardableResult
    func completeDemoIfNeeded(receiptID: UUID = UUID()) throws -> DemoCompletionResult {
        var player = try repository.loadPlayer()
        let result = OnboardingEngine.completeDemo(
            at: clock.wallNow(), receiptID: receiptID, in: &player
        )
        if case .rewarded = result { try repository.savePlayer(player) }
        return result
    }

    @discardableResult
    func purchaseDemoUpgrade(commandID: UUID = UUID()) throws -> UpgradePurchaseResult {
        var player = try repository.loadPlayer()
        let result = OnboardingEngine.purchaseRecommendedUpgrade(commandID: commandID, in: &player)
        if case .purchased = result { try repository.savePlayer(player) }
        return result
    }

    func recordPermission(
        _ kind: OnboardingPermissionKind,
        outcome: OnboardingPermissionOutcome
    ) throws -> PlayerState {
        var player = try repository.loadPlayer()
        OnboardingEngine.recordPermission(kind, outcome: outcome, in: &player)
        try repository.savePlayer(player)
        return player
    }

    func finishOnboarding() throws -> PlayerState {
        var player = try repository.loadPlayer()
        OnboardingEngine.finish(in: &player)
        try repository.savePlayer(player)
        return player
    }

    func select(plan: MinePlan) throws -> PlayerState {
        var player = try repository.loadPlayer()
        OnboardingEngine.select(plan: plan, in: &player)
        try repository.savePlayer(player)
        return player
    }

    func select(duration: SessionLength) throws -> PlayerState {
        var player = try repository.loadPlayer()
        OnboardingEngine.select(duration: duration, in: &player)
        try repository.savePlayer(player)
        return player
    }

    private func demoState(for player: PlayerState) -> DemoMiningState {
        let startedAt = player.demoStartedAt ?? clock.wallNow()
        let endsAt = startedAt.addingTimeInterval(Balance.demoDurationSeconds)
        return DemoMiningState(
            startedAt: startedAt,
            endsAt: endsAt,
            remainingSeconds: max(0, Int(ceil(endsAt.timeIntervalSince(clock.wallNow())))),
            isRewarded: player.demoRewardReceiptID != nil
        )
    }
}
