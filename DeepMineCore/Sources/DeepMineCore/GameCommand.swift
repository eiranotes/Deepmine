import Foundation

public struct GameCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let action: GameCommandAction

    public init(id: UUID = UUID(), createdAt: Date = Date(), action: GameCommandAction) {
        self.id = id
        self.createdAt = createdAt
        self.action = action
    }
}

public enum GameCommandAction: Codable, Equatable, Sendable {
    case upgradeEquipment(EquipmentKind)
    case purchasePermanentUpgrade(PermanentUpgradeKind)
    case prestige
    case startSession(length: SessionLength, plan: MinePlan)
    case abandonSession
    case open(GameOpenDestination)
}

public enum GameOpenDestination: String, Codable, CaseIterable, Sendable {
    case overview
    case session
    case equipment
    case prestige
}
