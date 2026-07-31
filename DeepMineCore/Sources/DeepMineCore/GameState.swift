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

public struct PlayerState: Codable, Equatable, Sendable {
    public internal(set) var resources: Resources
    public internal(set) var equipment: EquipmentLevels
    /// Highest level ever bought for each tool. Prestige keeps it so re-buying is
    /// discounted — the mine remembers the shaft it already dug.
    public internal(set) var rememberedEquipment: EquipmentLevels
    public internal(set) var runFocusCredits: Double
    public internal(set) var lifetimeFocusCredits: Double
    public internal(set) var completedSessionCount: Int
    public internal(set) var bonusDepthMeters: Int
    public internal(set) var history: [SessionHistoryEntry]
    public internal(set) var appliedCompletionIDs: Set<UUID>
    public internal(set) var appliedPurchaseIDs: Set<UUID>
    public internal(set) var dailyGoalMinutes: Int
    public internal(set) var streakDays: Int
    public internal(set) var dailyRecords: [DailyRecord]
    public internal(set) var usedRestWeeks: Set<ISOWeekKey>
    public internal(set) var latestDayKey: DayKey?
    public internal(set) var consecutiveVeinMisses: Int
    public internal(set) var permanentResonanceLevel: Int
    public internal(set) var unlockedThemes: Set<MineTheme>
    public internal(set) var selectedTheme: MineTheme
    public internal(set) var unlockedDecorations: Set<MineDecoration>
    public internal(set) var resonanceBoostPending: Bool
    public internal(set) var appliedVeinEffectIDs: Set<UUID>
    public internal(set) var earnedAchievementIDs: Set<String>
    public internal(set) var excavationMemoryLevel: Int
    public internal(set) var compressedTimeLevel: Int
    public internal(set) var prestigeIndex: Int
    public internal(set) var appliedPrestigeCommandIDs: Set<UUID>
    public internal(set) var appliedPermanentUpgradeCommandIDs: Set<UUID>
    public internal(set) var onboardingStage: OnboardingStage
    public internal(set) var demoStartedAt: Date?
    public internal(set) var demoCompletedAt: Date?
    public internal(set) var demoRewardReceiptID: UUID?
    public internal(set) var demoUpgradePurchaseID: UUID?
    public internal(set) var focusProtectionPermission: OnboardingPermissionOutcome
    public internal(set) var endAlertPermission: OnboardingPermissionOutcome
    public internal(set) var returnReminderPermission: OnboardingPermissionOutcome
    public internal(set) var lastSelectedPlan: MinePlan
    public internal(set) var lastSelectedDuration: SessionLength
    public internal(set) var mineFace: MineFaceState
    /// When the mine was last paid out. Nil means never settled, which is why a fresh
    /// install cannot claim an offline haul for the epoch.
    public internal(set) var lastSettledAt: Date?

    /// Derived from the rock the player has actually broken. Depth is the identity
    /// number of the mine, and in a clicker the only honest way to earn it is to break
    /// through it — focus credits amplify how fast that happens, they do not grant depth
    /// on their own.
    ///
    /// Single source of truth: `mineFace.segmentIndex`. `bonusDepthMeters` remains for
    /// abyss vein grants, which skip rock rather than break it.
    public var depthMeters: Int {
        let base = mineFace.depthMeters
        let bonus = max(0, bonusDepthMeters)
        return base > Int.max - bonus ? Int.max : base + bonus
    }

    public var unlockedEquipmentLevel: Int {
        Balance.maximumEquipmentLevel(forDepth: depthMeters)
    }

    public var isDeepMiningUnlocked: Bool {
        completedSessionCount >= Balance.deepUnlockCompletedSessions
    }

    public var permanentUpgrades: PermanentUpgradeLevels {
        PermanentUpgradeLevels(
            excavationMemory: excavationMemoryLevel,
            resonanceDetection: permanentResonanceLevel,
            compressedTime: compressedTimeLevel
        )
    }

    public init(
        resources: Resources = Resources(),
        equipment: EquipmentLevels = EquipmentLevels(),
        rememberedEquipment: EquipmentLevels? = nil,
        runFocusCredits: Double = 0,
        lifetimeFocusCredits: Double = 0,
        completedSessionCount: Int = 0,
        bonusDepthMeters: Int = 0,
        history: [SessionHistoryEntry] = [],
        appliedCompletionIDs: Set<UUID> = [],
        appliedPurchaseIDs: Set<UUID> = [],
        dailyGoalMinutes: Int = Balance.defaultDailyGoalMinutes,
        streakDays: Int = 0,
        dailyRecords: [DailyRecord] = [],
        usedRestWeeks: Set<ISOWeekKey> = [],
        latestDayKey: DayKey? = nil,
        consecutiveVeinMisses: Int = 0,
        permanentResonanceLevel: Int = 0,
        unlockedThemes: Set<MineTheme> = [.entry],
        selectedTheme: MineTheme = .entry,
        unlockedDecorations: Set<MineDecoration> = [],
        resonanceBoostPending: Bool = false,
        appliedVeinEffectIDs: Set<UUID> = [],
        earnedAchievementIDs: Set<String> = [],
        excavationMemoryLevel: Int = 0,
        compressedTimeLevel: Int = 0,
        prestigeIndex: Int = 0,
        appliedPrestigeCommandIDs: Set<UUID> = [],
        appliedPermanentUpgradeCommandIDs: Set<UUID> = [],
        onboardingStage: OnboardingStage = .premiseBlocks,
        demoStartedAt: Date? = nil,
        demoCompletedAt: Date? = nil,
        demoRewardReceiptID: UUID? = nil,
        demoUpgradePurchaseID: UUID? = nil,
        focusProtectionPermission: OnboardingPermissionOutcome = .notAsked,
        endAlertPermission: OnboardingPermissionOutcome = .notAsked,
        returnReminderPermission: OnboardingPermissionOutcome = .notAsked,
        lastSelectedPlan: MinePlan = .safe,
        lastSelectedDuration: SessionLength = .minutes25,
        mineFace: MineFaceState = MineFaceState(),
        lastSettledAt: Date? = nil
    ) {
        self.resources = resources
        self.equipment = equipment
        self.rememberedEquipment = Self.mergedRemembered(rememberedEquipment, equipment)
        self.runFocusCredits = runFocusCredits
        self.lifetimeFocusCredits = lifetimeFocusCredits
        self.completedSessionCount = completedSessionCount
        self.bonusDepthMeters = bonusDepthMeters
        self.history = Array(history.suffix(Balance.sessionHistoryLimit))
        self.appliedCompletionIDs = appliedCompletionIDs
        self.appliedPurchaseIDs = appliedPurchaseIDs
        self.dailyGoalMinutes = dailyGoalMinutes
        self.streakDays = streakDays
        self.dailyRecords = Array(dailyRecords.suffix(Balance.dailyRecordLimit))
        self.usedRestWeeks = usedRestWeeks
        self.latestDayKey = latestDayKey
        self.consecutiveVeinMisses = consecutiveVeinMisses
        self.permanentResonanceLevel = permanentResonanceLevel
        self.unlockedThemes = unlockedThemes.union([.entry])
        self.selectedTheme = unlockedThemes.contains(selectedTheme) || selectedTheme == .entry
            ? selectedTheme
            : .entry
        self.unlockedDecorations = unlockedDecorations
        self.resonanceBoostPending = resonanceBoostPending
        self.appliedVeinEffectIDs = appliedVeinEffectIDs
        self.earnedAchievementIDs = earnedAchievementIDs
        self.excavationMemoryLevel = excavationMemoryLevel
        self.compressedTimeLevel = compressedTimeLevel
        self.prestigeIndex = prestigeIndex
        self.appliedPrestigeCommandIDs = appliedPrestigeCommandIDs
        self.appliedPermanentUpgradeCommandIDs = appliedPermanentUpgradeCommandIDs
        self.onboardingStage = onboardingStage
        self.demoStartedAt = demoStartedAt
        self.demoCompletedAt = demoCompletedAt
        self.demoRewardReceiptID = demoRewardReceiptID
        self.demoUpgradePurchaseID = demoUpgradePurchaseID
        self.focusProtectionPermission = focusProtectionPermission
        self.endAlertPermission = endAlertPermission
        self.returnReminderPermission = returnReminderPermission
        self.lastSelectedPlan = lastSelectedPlan
        self.lastSelectedDuration = lastSelectedDuration
        self.mineFace = mineFace
        self.lastSettledAt = lastSettledAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resources = try container.decode(Resources.self, forKey: .resources)
        equipment = try container.decode(EquipmentLevels.self, forKey: .equipment)
        rememberedEquipment = Self.mergedRemembered(
            try container.decodeIfPresent(EquipmentLevels.self, forKey: .rememberedEquipment),
            equipment
        )
        runFocusCredits = try container.decode(Double.self, forKey: .runFocusCredits)
        lifetimeFocusCredits = try container.decode(Double.self, forKey: .lifetimeFocusCredits)
        completedSessionCount = try container.decode(Int.self, forKey: .completedSessionCount)
        bonusDepthMeters = try container.decode(Int.self, forKey: .bonusDepthMeters)
        let decodedHistory = try container.decode([SessionHistoryEntry].self, forKey: .history)
        history = Array(decodedHistory.suffix(Balance.sessionHistoryLimit))
        appliedCompletionIDs = try container.decode(Set<UUID>.self, forKey: .appliedCompletionIDs)
        appliedPurchaseIDs = try container.decode(Set<UUID>.self, forKey: .appliedPurchaseIDs)
        dailyGoalMinutes = try container.decode(Int.self, forKey: .dailyGoalMinutes)
        streakDays = try container.decode(Int.self, forKey: .streakDays)
        dailyRecords = Array(
            try container.decode([DailyRecord].self, forKey: .dailyRecords)
                .suffix(Balance.dailyRecordLimit)
        )
        usedRestWeeks = try container.decode(Set<ISOWeekKey>.self, forKey: .usedRestWeeks)
        latestDayKey = try container.decodeIfPresent(DayKey.self, forKey: .latestDayKey)
        consecutiveVeinMisses = try container.decode(Int.self, forKey: .consecutiveVeinMisses)
        permanentResonanceLevel = try container.decode(Int.self, forKey: .permanentResonanceLevel)
        unlockedThemes = try container.decode(Set<MineTheme>.self, forKey: .unlockedThemes)
        unlockedThemes.insert(.entry)
        selectedTheme = try container.decode(MineTheme.self, forKey: .selectedTheme)
        if !unlockedThemes.contains(selectedTheme) { selectedTheme = .entry }
        unlockedDecorations = try container.decode(Set<MineDecoration>.self, forKey: .unlockedDecorations)
        resonanceBoostPending = try container.decode(Bool.self, forKey: .resonanceBoostPending)
        appliedVeinEffectIDs = try container.decode(Set<UUID>.self, forKey: .appliedVeinEffectIDs)
        earnedAchievementIDs = try container.decodeIfPresent(
            Set<String>.self, forKey: .earnedAchievementIDs
        ) ?? []
        excavationMemoryLevel = try container.decode(Int.self, forKey: .excavationMemoryLevel)
        compressedTimeLevel = try container.decode(Int.self, forKey: .compressedTimeLevel)
        prestigeIndex = try container.decode(Int.self, forKey: .prestigeIndex)
        appliedPrestigeCommandIDs = try container.decode(Set<UUID>.self, forKey: .appliedPrestigeCommandIDs)
        appliedPermanentUpgradeCommandIDs = try container.decode(
            Set<UUID>.self,
            forKey: .appliedPermanentUpgradeCommandIDs
        )
        onboardingStage = try container.decodeIfPresent(
            OnboardingStage.self, forKey: .onboardingStage
        ) ?? .premiseBlocks
        demoStartedAt = try container.decodeIfPresent(Date.self, forKey: .demoStartedAt)
        demoCompletedAt = try container.decodeIfPresent(Date.self, forKey: .demoCompletedAt)
        demoRewardReceiptID = try container.decodeIfPresent(UUID.self, forKey: .demoRewardReceiptID)
        demoUpgradePurchaseID = try container.decodeIfPresent(UUID.self, forKey: .demoUpgradePurchaseID)
        focusProtectionPermission = try container.decodeIfPresent(
            OnboardingPermissionOutcome.self, forKey: .focusProtectionPermission
        ) ?? .notAsked
        endAlertPermission = try container.decodeIfPresent(
            OnboardingPermissionOutcome.self, forKey: .endAlertPermission
        ) ?? .notAsked
        returnReminderPermission = try container.decodeIfPresent(
            OnboardingPermissionOutcome.self, forKey: .returnReminderPermission
        ) ?? .notAsked
        lastSelectedPlan = try container.decodeIfPresent(
            MinePlan.self, forKey: .lastSelectedPlan
        ) ?? .safe
        lastSelectedDuration = try container.decodeIfPresent(
            SessionLength.self, forKey: .lastSelectedDuration
        ) ?? .minutes25
        // Saves written before the pivot have no rock face. Seeding it from the depth
        // those saves had earned under the old focus-derived rule keeps an existing
        // player's progress instead of dropping them back to the surface.
        if let face = try container.decodeIfPresent(MineFaceState.self, forKey: .mineFace) {
            mineFace = face
        } else {
            let legacyDepth = ProgressionEngine.depth(
                lifetimeFocusCredits: lifetimeFocusCredits,
                bonusDepthMeters: 0
            )
            mineFace = MineFaceState(
                segmentIndex: ProgressionEngine.segmentIndex(forDepth: legacyDepth)
            )
        }
        lastSettledAt = try container.decodeIfPresent(Date.self, forKey: .lastSettledAt)
    }

    /// Saves written before the remembered peak existed fall back to current levels,
    /// so an existing player never loses a discount they already earned.
    private static func mergedRemembered(
        _ remembered: EquipmentLevels?,
        _ equipment: EquipmentLevels
    ) -> EquipmentLevels {
        guard let remembered else { return equipment }
        return EquipmentLevels(
            drill: max(remembered.drill, equipment.drill),
            cart: max(remembered.cart, equipment.cart),
            lamp: max(remembered.lamp, equipment.lamp)
        )
    }
}
