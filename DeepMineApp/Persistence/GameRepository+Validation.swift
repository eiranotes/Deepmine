import Foundation

extension GameRepository {
    func validateVersions(
        root: PlayerStateEntity,
        equipment: EquipmentStateEntity,
        sessions: [SessionRecordEntity],
        daily: [DailyRecordEntity],
        purchases: PurchaseStateEntity
    ) throws {
        try validate(root.schemaVersion, entity: "PlayerStateEntity")
        try validate(equipment.schemaVersion, entity: "EquipmentStateEntity")
        try sessions.forEach { try validate($0.schemaVersion, entity: "SessionRecordEntity") }
        try daily.forEach { try validate($0.schemaVersion, entity: "DailyRecordEntity") }
        try validate(purchases.schemaVersion, entity: "PurchaseStateEntity")
    }

    private func validate(_ version: Int, entity: String) throws {
        guard version == Self.currentSchemaVersion else {
            throw GamePersistenceError.unsupportedSchemaVersion(entity: entity, found: version)
        }
    }
}
