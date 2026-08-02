import DeepMineCore
import Foundation

@MainActor
extension GameStore {
    func mineLedger() throws -> MineLedger {
        MineLedgerEngine.summarize(try repository.loadPlayer())
    }

    @discardableResult
    func purchaseEquipment(
        _ equipment: EquipmentKind,
        commandID: UUID = UUID()
    ) throws -> UpgradePurchaseResult {
        var player = try repository.loadPlayer()
        let result = EquipmentEngine.purchase(
            UpgradePurchaseCommand(id: commandID, equipment: equipment),
            in: &player
        )
        if case .purchased = result {
            AchievementEngine.evaluate(in: &player)
            try repository.savePlayer(player)
        }
        return result
    }

    @discardableResult
    func purchaseEquipmentBulk(
        _ equipment: EquipmentKind,
        maximumPurchases: Int? = nil,
        stopAtRememberedLevel: Bool = false,
        commandID: UUID = UUID()
    ) throws -> BulkUpgradePurchaseResult {
        var player = try repository.loadPlayer()
        let result = EquipmentEngine.purchaseBulk(
            BulkUpgradePurchaseCommand(
                id: commandID,
                equipment: equipment,
                maximumPurchases: maximumPurchases,
                stopAtRememberedLevel: stopAtRememberedLevel
            ),
            in: &player
        )
        if case .purchased = result {
            AchievementEngine.evaluate(in: &player)
            try repository.savePlayer(player)
        }
        return result
    }

    @discardableResult
    func purchaseEquipmentModification(
        _ modification: EquipmentModificationKind,
        commandID: UUID = UUID()
    ) throws -> EquipmentModificationPurchaseResult {
        var player = try repository.loadPlayer()
        let result = EquipmentModificationEngine.purchase(
            EquipmentModificationCommand(id: commandID, modification: modification),
            in: &player
        )
        if case .purchased = result { try repository.savePlayer(player) }
        return result
    }

    @discardableResult
    func purchaseRefinement(
        _ equipment: EquipmentKind,
        commandID: UUID = UUID()
    ) throws -> RefinementPurchaseResult {
        var player = try repository.loadPlayer()
        let result = RefinementEngine.purchase(
            RefinementPurchaseCommand(id: commandID, equipment: equipment),
            in: &player
        )
        if case .refined = result { try repository.savePlayer(player) }
        return result
    }

    func recommendedUpgrade(
        verificationGrade _: VerificationGrade = .sealed
    ) throws -> UpgradeRecommendation? {
        recommendedUpgrade(for: try repository.loadPlayer())
    }

    func recommendedUpgrade(
        for player: PlayerState,
        verificationGrade _: VerificationGrade = .sealed
    ) -> UpgradeRecommendation? {
        UpgradeAdvisor.recommendForMining(for: player)
    }
}
