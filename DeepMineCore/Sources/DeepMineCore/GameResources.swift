import Foundation

public struct Resources: Codable, Equatable, Sendable {
    public var ore: Double
    public var crystals: Int
    public var coreShards: Int

    public init(ore: Double = 0, crystals: Int = 0, coreShards: Int = 0) {
        self.ore = ore
        self.crystals = crystals
        self.coreShards = coreShards
    }
}

public struct SessionHistoryEntry: Codable, Equatable, Sendable {
    public let completionID: UUID
    public let endedAt: Date
    public let focusedMinutes: Int
    public let focusCredits: Double
    public let plan: MinePlan
    public let verificationGrade: VerificationGrade
    public let oreEarned: Double
    public let vein: VeinKind?
    public let depthAfter: Int
    public let completed: Bool

    public init(
        completionID: UUID,
        endedAt: Date,
        focusedMinutes: Int,
        focusCredits: Double,
        plan: MinePlan,
        verificationGrade: VerificationGrade,
        oreEarned: Double,
        vein: VeinKind?,
        depthAfter: Int,
        completed: Bool
    ) {
        self.completionID = completionID
        self.endedAt = endedAt
        self.focusedMinutes = focusedMinutes
        self.focusCredits = focusCredits
        self.plan = plan
        self.verificationGrade = verificationGrade
        self.oreEarned = oreEarned
        self.vein = vein
        self.depthAfter = depthAfter
        self.completed = completed
    }
}
