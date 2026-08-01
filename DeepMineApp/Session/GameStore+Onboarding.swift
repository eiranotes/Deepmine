import DeepMineCore
import Foundation

@MainActor
extension GameStore {
    func playerState() throws -> PlayerState {
        try repository.loadPlayer()
    }

    func strikeOnboardingRock(
        hitWeakPoint: Bool = false,
        receiptID: UUID = UUID()
    ) throws -> DemoStrikeResult {
        var player = try repository.loadPlayer()
        var generator = SystemRandomNumberGenerator()
        let result = OnboardingEngine.strikeDemo(
            at: clock.wallNow(),
            receiptID: receiptID,
            hitWeakPoint: hitWeakPoint,
            using: &generator,
            in: &player
        )
        if result != .alreadyRewarded { try repository.savePlayer(player) }
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

}
