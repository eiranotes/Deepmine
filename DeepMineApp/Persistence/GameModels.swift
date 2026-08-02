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
    /// Legacy column, kept so a store written before unbounded growth still opens. New
    /// writes also fill it with a saturating value for anything that still reads it.
    var ore: Double
    /// The wallet as a `BigNumber`. Split into two columns rather than encoded, so the
    /// value stays queryable and a zero pair reads as "this row predates the migration".
    var oreMantissa: Double = 0
    var oreExponent: Int = 0
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
    /// Run-scoped equipment branch choices. Empty data is the legacy/default state.
    var equipmentModificationsData: Data = Data()
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
    // The clicker's position in the rock. Without these the mine face was rebuilt at the
    // surface on every launch: every tap between one segment break and the next relaunch
    // was lost, and so was the depth those breaks had earned.
    //
    // Defaults are supplied on every property so an existing v1 store migrates in place
    // rather than failing closed on an unknown schema.
    var mineFaceSegmentIndex: Int = 0
    /// `BigNumber` as its own JSON. Integrity outgrows `Double` in the deep regions, so
    /// storing a plain number here would silently round the face away.
    var mineFaceRemainingIntegrityData: Data = Data()
    var mineFaceImpact: Double = 0
    var mineFaceLifetimeSegmentsBroken: Int = 0
    var mineFaceLifetimeSeamsBroken: Int = 0
    var mineFaceBoreHistoryData: Data = Data()
    var deepestSegmentIndex: Int = 0
    var runSegmentsBroken: Int = 0
    var lastSettledAt: Date?

    init(schemaVersion: Int = GameSchemaV1.version) {
        id = GameSchemaV1.singletonID
        self.schemaVersion = schemaVersion
        ore = 0
        oreMantissa = 0
        oreExponent = 0
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
