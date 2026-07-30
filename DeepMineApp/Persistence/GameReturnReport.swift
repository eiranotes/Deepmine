import DeepMineCore
import Foundation

/// What the vein actually handed over, so the report can name a number instead of
/// saying something was added.
enum GameVeinYield: Codable, Equatable, Sendable {
    case oreMultiplier(Double)
    case crystals(Int)
    case themeUnlocked
    case decorationUnlocked
    case nextSessionDoubled
    case bonusDepth(Int)
}

struct GameReturnReport: Codable, Equatable, Sendable {
    let sessionID: UUID
    let completionID: UUID
    let outcome: SessionOutcome
    let verificationGrade: VerificationGrade
    let focusedMinutes: Int
    let oreEarned: Double
    let vein: VeinKind?
    let veinYield: GameVeinYield?
    let depthMeters: Int
    let depthGainedMeters: Int
    let streakDays: Int
    let streakEarnedToday: Bool
    let todayFocusedMinutes: Int
    let todayGoalMinutes: Int
    let earnedAchievementIDs: [String]
    let completedAt: Date
    let clockAssessment: DeepMineCore.ClockIntegrityAssessment
    let warnings: [String]

    init(
        sessionID: UUID,
        completionID: UUID,
        outcome: SessionOutcome,
        verificationGrade: VerificationGrade,
        focusedMinutes: Int,
        oreEarned: Double,
        vein: VeinKind?,
        veinYield: GameVeinYield? = nil,
        depthMeters: Int,
        depthGainedMeters: Int = 0,
        streakDays: Int = 0,
        streakEarnedToday: Bool = false,
        todayFocusedMinutes: Int = 0,
        todayGoalMinutes: Int = Balance.defaultDailyGoalMinutes,
        earnedAchievementIDs: [String] = [],
        completedAt: Date,
        clockAssessment: DeepMineCore.ClockIntegrityAssessment,
        warnings: [String]
    ) {
        self.sessionID = sessionID
        self.completionID = completionID
        self.outcome = outcome
        self.verificationGrade = verificationGrade
        self.focusedMinutes = focusedMinutes
        self.oreEarned = oreEarned
        self.vein = vein
        self.veinYield = veinYield
        self.depthMeters = depthMeters
        self.depthGainedMeters = depthGainedMeters
        self.streakDays = streakDays
        self.streakEarnedToday = streakEarnedToday
        self.todayFocusedMinutes = todayFocusedMinutes
        self.todayGoalMinutes = todayGoalMinutes
        self.earnedAchievementIDs = earnedAchievementIDs
        self.completedAt = completedAt
        self.clockAssessment = clockAssessment
        self.warnings = warnings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionID = try container.decode(UUID.self, forKey: .sessionID)
        completionID = try container.decode(UUID.self, forKey: .completionID)
        outcome = try container.decode(SessionOutcome.self, forKey: .outcome)
        verificationGrade = try container.decode(VerificationGrade.self, forKey: .verificationGrade)
        focusedMinutes = try container.decode(Int.self, forKey: .focusedMinutes)
        oreEarned = try container.decode(Double.self, forKey: .oreEarned)
        vein = try container.decodeIfPresent(VeinKind.self, forKey: .vein)
        veinYield = try container.decodeIfPresent(GameVeinYield.self, forKey: .veinYield)
        depthMeters = try container.decode(Int.self, forKey: .depthMeters)
        depthGainedMeters = try container.decodeIfPresent(Int.self, forKey: .depthGainedMeters) ?? 0
        streakDays = try container.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        streakEarnedToday = try container
            .decodeIfPresent(Bool.self, forKey: .streakEarnedToday) ?? false
        todayFocusedMinutes = try container
            .decodeIfPresent(Int.self, forKey: .todayFocusedMinutes) ?? 0
        todayGoalMinutes = try container
            .decodeIfPresent(Int.self, forKey: .todayGoalMinutes) ?? Balance.defaultDailyGoalMinutes
        earnedAchievementIDs = try container
            .decodeIfPresent([String].self, forKey: .earnedAchievementIDs) ?? []
        completedAt = try container.decode(Date.self, forKey: .completedAt)
        clockAssessment = try container.decode(
            DeepMineCore.ClockIntegrityAssessment.self,
            forKey: .clockAssessment
        )
        warnings = try container.decode([String].self, forKey: .warnings)
    }

    func adding(warnings newWarnings: [String]) -> GameReturnReport {
        GameReturnReport(
            sessionID: sessionID, completionID: completionID, outcome: outcome,
            verificationGrade: verificationGrade, focusedMinutes: focusedMinutes,
            oreEarned: oreEarned, vein: vein, veinYield: veinYield,
            depthMeters: depthMeters, depthGainedMeters: depthGainedMeters,
            streakDays: streakDays, streakEarnedToday: streakEarnedToday,
            todayFocusedMinutes: todayFocusedMinutes, todayGoalMinutes: todayGoalMinutes,
            earnedAchievementIDs: earnedAchievementIDs,
            completedAt: completedAt, clockAssessment: clockAssessment,
            warnings: Array((warnings + newWarnings).prefix(8))
        )
    }
}
