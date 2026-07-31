import Foundation

public enum SessionPhase: String, Codable, CaseIterable, Sendable {
    case preparing
    case mining
    case completed
    case abandoned
}

public enum SessionAction: String, Codable, CaseIterable, Sendable {
    case start
    case complete
    case abandon
}

public enum SessionLength: String, Codable, CaseIterable, Sendable {
    case minutes15
    case minutes25
    case minutes50

    public var minutes: Int { Balance.minutes(for: self) }
}

public enum MinePlan: String, Codable, CaseIterable, Sendable {
    case safe
    case deep
    case survey
}

public enum VerificationGrade: String, Codable, CaseIterable, Sendable {
    case sealed
    case open
    case collapsed

    public static func resolve(
        blockingEnabled: Bool,
        shieldMaintained: Bool,
        forcedShieldRemoval: Bool
    ) -> Self {
        if forcedShieldRemoval { return .collapsed }
        return blockingEnabled && shieldMaintained ? .sealed : .open
    }
}

public enum VeinKind: String, Codable, CaseIterable, Sendable {
    case blue
    case crystal
    case vault
    case resonance
    case abyss
}

public struct EquipmentLevels: Codable, Equatable, Sendable {
    public var drill: Int
    public var cart: Int
    public var lamp: Int

    public init(
        drill: Int = Balance.minimumEquipmentLevel,
        cart: Int = Balance.minimumEquipmentLevel,
        lamp: Int = Balance.minimumEquipmentLevel
    ) {
        self.drill = drill
        self.cart = cart
        self.lamp = lamp
    }
}

public struct PermanentUpgradeLevels: Codable, Equatable, Sendable {
    public var excavationMemory: Int
    public var resonanceDetection: Int
    public var compressedTime: Int

    public init(
        excavationMemory: Int = 0,
        resonanceDetection: Int = 0,
        compressedTime: Int = 0
    ) {
        self.excavationMemory = excavationMemory
        self.resonanceDetection = resonanceDetection
        self.compressedTime = compressedTime
    }
}

public enum SessionOutcome: Codable, Equatable, Sendable {
    case completed
    case abandoned(elapsedMinutes: Int)
}

public struct RewardInput: Codable, Equatable, Sendable {
    public let completionID: UUID
    public let outcome: SessionOutcome
    public let sessionLength: SessionLength
    public let plan: MinePlan
    public let verificationGrade: VerificationGrade
    public let growthFocusCredits: Double
    public let streakDays: Int
    public let dailySessionNumber: Int
    public let equipment: EquipmentLevels
    public let vein: VeinKind?
    public let resonanceBoostActive: Bool
    public let permanentUpgrades: PermanentUpgradeLevels

    public init(
        completionID: UUID,
        outcome: SessionOutcome,
        sessionLength: SessionLength,
        plan: MinePlan,
        verificationGrade: VerificationGrade,
        growthFocusCredits: Double,
        streakDays: Int,
        dailySessionNumber: Int,
        equipment: EquipmentLevels,
        vein: VeinKind?,
        resonanceBoostActive: Bool,
        permanentUpgrades: PermanentUpgradeLevels = PermanentUpgradeLevels()
    ) {
        self.completionID = completionID
        self.outcome = outcome
        self.sessionLength = sessionLength
        self.plan = plan
        self.verificationGrade = verificationGrade
        self.growthFocusCredits = growthFocusCredits
        self.streakDays = streakDays
        self.dailySessionNumber = dailySessionNumber
        self.equipment = equipment
        self.vein = vein
        self.resonanceBoostActive = resonanceBoostActive
        self.permanentUpgrades = permanentUpgrades
    }
}

public struct RewardMultiplierBreakdown: Codable, Equatable, Sendable {
    public let focusCredits: Double
    public let baseOre: Double
    public let growth: Double
    public let length: Double
    public let plan: Double
    public let verification: Double
    public let streak: Double
    public let dailyOrder: Double
    public let equipment: Double
    public let vein: Double
    public let abandonment: Double
    public let permanent: Double

    public var combinedMultiplier: Double {
        [growth, length, plan, verification, streak, dailyOrder, equipment, vein, abandonment, permanent]
            .reduce(1.0) { partial, next in
                guard partial != 0, next != 0 else { return 0 }
                guard partial <= Double.greatestFiniteMagnitude / next else {
                    return Double.greatestFiniteMagnitude
                }
                return partial * next
            }
    }
}

public struct RewardResult: Codable, Equatable, Sendable {
    public let completionID: UUID
    public let focusedMinutes: Int
    public let focusCredits: Double
    public let ore: Double
    public let breakdown: RewardMultiplierBreakdown
    public let wasDuplicate: Bool

    public init(
        completionID: UUID,
        focusedMinutes: Int,
        focusCredits: Double,
        ore: Double,
        breakdown: RewardMultiplierBreakdown,
        wasDuplicate: Bool
    ) {
        self.completionID = completionID
        self.focusedMinutes = focusedMinutes
        self.focusCredits = focusCredits
        self.ore = ore
        self.breakdown = breakdown
        self.wasDuplicate = wasDuplicate
    }
}

public struct CompletionRegistry: Codable, Equatable, Sendable {
    public private(set) var awardedCompletionIDs: Set<UUID>

    public init(awardedCompletionIDs: Set<UUID> = []) {
        self.awardedCompletionIDs = awardedCompletionIDs
    }

    mutating func claim(_ completionID: UUID) -> Bool {
        awardedCompletionIDs.insert(completionID).inserted
    }
}

public enum RewardCalculationError: Error, Codable, Equatable, Sendable {
    case invalidValue(field: String)
}
