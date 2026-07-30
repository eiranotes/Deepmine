import DeepMineCore
import Foundation
import SwiftData

enum GameSchemaV1 {
    static let version = 1
    static let singletonID = UUID(uuidString: "44454550-4D49-4E45-0000-000000000001")!

    static var schema: Schema {
        Schema([
            PlayerStateEntity.self,
            EquipmentStateEntity.self,
            SessionRecordEntity.self,
            DailyRecordEntity.self,
            PurchaseStateEntity.self,
            GameSessionEntity.self
        ])
    }
}

@Model
final class PlayerStateEntity {
    @Attribute(.unique) var id: UUID
    var schemaVersion: Int
    var ore: Double
    var crystals: Int
    var coreShards: Int
    var runFocusCredits: Double
    var lifetimeFocusCredits: Double
    var completedSessionCount: Int
    var bonusDepthMeters: Int
    var dailyGoalMinutes: Int
    var streakDays: Int
    var latestDayYear: Int?
    var latestDayMonth: Int?
    var latestDayDay: Int?
    var consecutiveVeinMisses: Int
    var permanentResonanceLevel: Int
    var selectedThemeRawValue: String
    var resonanceBoostPending: Bool
    var excavationMemoryLevel: Int
    var compressedTimeLevel: Int
    var prestigeIndex: Int
    var appliedCompletionIDsData: Data
    var usedRestWeeksData: Data
    var unlockedThemesData: Data
    var unlockedDecorationsData: Data
    var appliedVeinEffectIDsData: Data
    var appliedPrestigeCommandIDsData: Data
    var onboardingStageRawValue: String = "premiseBlocks"
    var demoStartedAt: Date?
    var demoCompletedAt: Date?
    var demoRewardReceiptID: UUID?
    var demoUpgradePurchaseID: UUID?
    var focusProtectionPermissionRawValue: String = "notAsked"
    var endAlertPermissionRawValue: String = "notAsked"
    var returnReminderPermissionRawValue: String = "notAsked"
    var lastSelectedPlanRawValue: String = "safe"
    var lastSelectedDurationRawValue: String = "minutes25"

    init(schemaVersion: Int = GameSchemaV1.version) {
        id = GameSchemaV1.singletonID
        self.schemaVersion = schemaVersion
        ore = 0
        crystals = 0
        coreShards = 0
        runFocusCredits = 0
        lifetimeFocusCredits = 0
        completedSessionCount = 0
        bonusDepthMeters = 0
        dailyGoalMinutes = 25
        streakDays = 0
        consecutiveVeinMisses = 0
        permanentResonanceLevel = 0
        selectedThemeRawValue = "entry"
        resonanceBoostPending = false
        excavationMemoryLevel = 0
        compressedTimeLevel = 0
        prestigeIndex = 0
        appliedCompletionIDsData = Data()
        usedRestWeeksData = Data()
        unlockedThemesData = Data()
        unlockedDecorationsData = Data()
        appliedVeinEffectIDsData = Data()
        appliedPrestigeCommandIDsData = Data()
        onboardingStageRawValue = OnboardingStage.premiseBlocks.rawValue
        focusProtectionPermissionRawValue = OnboardingPermissionOutcome.notAsked.rawValue
        endAlertPermissionRawValue = OnboardingPermissionOutcome.notAsked.rawValue
        returnReminderPermissionRawValue = OnboardingPermissionOutcome.notAsked.rawValue
        lastSelectedPlanRawValue = MinePlan.safe.rawValue
        lastSelectedDurationRawValue = SessionLength.minutes25.rawValue
    }
}

@Model
final class EquipmentStateEntity {
    @Attribute(.unique) var id: UUID
    var schemaVersion: Int
    var drillLevel: Int
    var cartLevel: Int
    var lampLevel: Int

    init(schemaVersion: Int = GameSchemaV1.version) {
        id = GameSchemaV1.singletonID
        self.schemaVersion = schemaVersion
        drillLevel = 1
        cartLevel = 1
        lampLevel = 1
    }
}

@Model
final class SessionRecordEntity {
    @Attribute(.unique) var completionID: UUID
    var schemaVersion: Int
    var endedAt: Date
    var focusedMinutes: Int
    var focusCredits: Double
    var planRawValue: String
    var verificationGradeRawValue: String
    var oreEarned: Double
    var veinRawValue: String?
    var depthAfter: Int
    var completed: Bool
    var sortIndex: Int

    init(completionID: UUID, schemaVersion: Int = GameSchemaV1.version) {
        self.completionID = completionID
        self.schemaVersion = schemaVersion
        endedAt = .distantPast
        focusedMinutes = 0
        focusCredits = 0
        planRawValue = "safe"
        verificationGradeRawValue = "open"
        oreEarned = 0
        depthAfter = 0
        completed = false
        sortIndex = 0
    }
}

@Model
final class DailyRecordEntity {
    @Attribute(.unique) var id: String
    var schemaVersion: Int
    var year: Int
    var month: Int
    var day: Int
    var focusedMinutes: Int
    var goalMinutes: Int
    var sessionCount: Int
    var goalEarned: Bool
    var streakApplied: Bool
    var wasRestDay: Bool
    var isFinalized: Bool
    var sortIndex: Int

    init(year: Int, month: Int, day: Int, schemaVersion: Int = GameSchemaV1.version) {
        id = String(format: "%04d-%02d-%02d", year, month, day)
        self.schemaVersion = schemaVersion
        self.year = year
        self.month = month
        self.day = day
        focusedMinutes = 0
        goalMinutes = 0
        sessionCount = 0
        goalEarned = false
        streakApplied = false
        wasRestDay = false
        isFinalized = false
        sortIndex = 0
    }
}

@Model
final class PurchaseStateEntity {
    @Attribute(.unique) var id: UUID
    var schemaVersion: Int
    var appliedPurchaseIDsData: Data
    var appliedPermanentUpgradeCommandIDsData: Data
    var appliedGameCommandIDsData: Data

    init(schemaVersion: Int = GameSchemaV1.version) {
        id = GameSchemaV1.singletonID
        self.schemaVersion = schemaVersion
        appliedPurchaseIDsData = Data()
        appliedPermanentUpgradeCommandIDsData = Data()
        appliedGameCommandIDsData = Data()
    }
}

extension PlayerStateEntity {
    func apply(_ state: PlayerState) {
        ore = state.resources.ore
        crystals = state.resources.crystals
        coreShards = state.resources.coreShards
        runFocusCredits = state.runFocusCredits
        lifetimeFocusCredits = state.lifetimeFocusCredits
        completedSessionCount = state.completedSessionCount
        bonusDepthMeters = state.bonusDepthMeters
        dailyGoalMinutes = state.dailyGoalMinutes
        streakDays = state.streakDays
        latestDayYear = state.latestDayKey?.year
        latestDayMonth = state.latestDayKey?.month
        latestDayDay = state.latestDayKey?.day
        consecutiveVeinMisses = state.consecutiveVeinMisses
        permanentResonanceLevel = state.permanentResonanceLevel
        selectedThemeRawValue = state.selectedTheme.rawValue
        resonanceBoostPending = state.resonanceBoostPending
        excavationMemoryLevel = state.excavationMemoryLevel
        compressedTimeLevel = state.compressedTimeLevel
        prestigeIndex = state.prestigeIndex
        onboardingStageRawValue = state.onboardingStage.rawValue
        demoStartedAt = state.demoStartedAt
        demoCompletedAt = state.demoCompletedAt
        demoRewardReceiptID = state.demoRewardReceiptID
        demoUpgradePurchaseID = state.demoUpgradePurchaseID
        focusProtectionPermissionRawValue = state.focusProtectionPermission.rawValue
        endAlertPermissionRawValue = state.endAlertPermission.rawValue
        returnReminderPermissionRawValue = state.returnReminderPermission.rawValue
        lastSelectedPlanRawValue = state.lastSelectedPlan.rawValue
        lastSelectedDurationRawValue = state.lastSelectedDuration.rawValue
    }

    func latestDayKey() throws -> DayKey? {
        let parts = [latestDayYear, latestDayMonth, latestDayDay]
        guard parts.contains(where: { $0 != nil }) else { return nil }
        guard let year = latestDayYear, let month = latestDayMonth, let day = latestDayDay else {
            throw GamePersistenceError.invalidStoredValue(
                field: "latestDayKey",
                value: "incomplete"
            )
        }
        return DayKey(year: year, month: month, day: day)
    }
}

extension SessionRecordEntity {
    func apply(_ record: SessionHistoryEntry, sortIndex: Int) {
        endedAt = record.endedAt
        focusedMinutes = record.focusedMinutes
        focusCredits = record.focusCredits
        planRawValue = record.plan.rawValue
        verificationGradeRawValue = record.verificationGrade.rawValue
        oreEarned = record.oreEarned
        veinRawValue = record.vein?.rawValue
        depthAfter = record.depthAfter
        completed = record.completed
        self.sortIndex = sortIndex
    }

    func coreRecord() throws -> SessionHistoryEntry {
        guard let plan = MinePlan(rawValue: planRawValue) else {
            throw GamePersistenceError.invalidStoredValue(field: "plan", value: planRawValue)
        }
        guard let grade = VerificationGrade(rawValue: verificationGradeRawValue) else {
            throw GamePersistenceError.invalidStoredValue(
                field: "verificationGrade",
                value: verificationGradeRawValue
            )
        }
        let vein: VeinKind?
        if let veinRawValue {
            guard let parsed = VeinKind(rawValue: veinRawValue) else {
                throw GamePersistenceError.invalidStoredValue(field: "vein", value: veinRawValue)
            }
            vein = parsed
        } else {
            vein = nil
        }
        return SessionHistoryEntry(
            completionID: completionID,
            endedAt: endedAt,
            focusedMinutes: focusedMinutes,
            focusCredits: focusCredits,
            plan: plan,
            verificationGrade: grade,
            oreEarned: oreEarned,
            vein: vein,
            depthAfter: depthAfter,
            completed: completed
        )
    }
}
