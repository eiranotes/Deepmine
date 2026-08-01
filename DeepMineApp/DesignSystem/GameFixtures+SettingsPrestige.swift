import DeepMineCore

extension GameFixtures {
    static func settingsPlayer(named name: String?) -> PlayerState? {
        switch name {
        // Themes unlock on depth, and depth is broken rock, so a locked theme needs a
        // shallow face rather than a small credit balance.
        case "theme-locked":
            settingsBase(unlockedThemes: [.entry], segmentIndex: 0)
        case "theme-unlocked":
            settingsBase(unlockedThemes: Set(MineTheme.allCases), selectedTheme: .crystal)
        case "settings-ready", "settings-denied", "settings-needs-list",
             "settings-recovery", "settings-feedback-off":
            settingsBase()
        case "prestige-ineligible":
            settingsBase(runSegmentsBroken: PrestigeEngine.target(prestigeIndex: 0) - 1)
        case "prestige-ready":
            settingsBase(
                resources: Resources(ore: 24_800, crystals: 8, coreShards: 2),
                equipment: EquipmentLevels(drill: 9, cart: 7, lamp: 6),
                runSegmentsBroken: PrestigeEngine.target(prestigeIndex: 0)
            )
        case "prestige-shards":
            settingsBase(resources: Resources(coreShards: 6), prestigeIndex: 1)
        default:
            nil
        }
    }

    static func settingsSnapshot(named name: String?) -> SettingsPermissionSnapshot {
        switch name {
        case "settings-needs-list":
            SettingsPermissionSnapshot(
                focus: .needsSelection,
                endAlert: .ready,
                returnReminder: .ready,
                selectedApplications: 0,
                selectedCategories: 0
            )
        case "settings-denied":
            SettingsPermissionSnapshot(
                focus: .denied,
                endAlert: .denied,
                returnReminder: .denied,
                selectedApplications: 0,
                selectedCategories: 0
            )
        default:
            .ready
        }
    }

    static func hasRecoveryNotice(named name: String?) -> Bool {
        name == "settings-recovery"
    }

    static func isSettingsPrestigeFixture(_ name: String?) -> Bool {
        settingsPlayer(named: name) != nil
    }

    private static func settingsBase(
        resources: Resources = Resources(ore: 1_840, crystals: 4),
        equipment: EquipmentLevels = EquipmentLevels(drill: 4, cart: 3, lamp: 2),
        runFocusCredits: Double = 12,
        lifetimeFocusCredits: Double = 64,
        runSegmentsBroken: Int = 12,
        unlockedThemes: Set<MineTheme> = [.entry, .crystal],
        selectedTheme: MineTheme = .entry,
        prestigeIndex: Int = 0,
        segmentIndex: Int = 400
    ) -> PlayerState {
        PlayerState(
            resources: resources,
            equipment: equipment,
            runFocusCredits: runFocusCredits,
            lifetimeFocusCredits: lifetimeFocusCredits,
            runSegmentsBroken: runSegmentsBroken,
            completedSessionCount: 12,
            dailyGoalMinutes: Balance.defaultDailyGoalMinutes,
            streakDays: 7,
            unlockedThemes: unlockedThemes,
            selectedTheme: selectedTheme,
            prestigeIndex: prestigeIndex,
            onboardingStage: .complete,
            // Themes unlock on depth, and depth is broken rock now (D-040). A settings
            // fixture with no mine face has every depth-gated row locked.
            mineFace: MineFaceState(segmentIndex: segmentIndex)
        )
    }
}
