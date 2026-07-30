import DeepMineCore
import Foundation

struct ReturnReportSeed: Sendable {
    let player: PlayerState
    let report: GameReturnReport
    let cleanupSession: PersistedGameSession
}

extension GameFixtures {
    static func returnSeed(named name: String?) -> ReturnReportSeed? {
        guard let name, name.hasPrefix("return-") else { return nil }
        let vein: VeinKind?
        switch name {
        case "return-blue": vein = .blue
        case "return-crystal": vein = .crystal
        case "return-vault": vein = .vault
        case "return-resonance": vein = .resonance
        case "return-abyss": vein = .abyss
        default: vein = nil
        }
        let abandoned = name == "return-abandoned"
        let collapsed = name == "return-collapsed" || name == "return-unaffordable"
        let completionID = returnUUID(name)
        let focusedMinutes = abandoned ? 8 : 25
        let outcome: SessionOutcome = abandoned
            ? .abandoned(elapsedMinutes: focusedMinutes)
            : .completed
        let grade: VerificationGrade = collapsed ? .collapsed : .sealed
        let plan: MinePlan = collapsed ? .deep : .safe
        let availableBefore = name == "return-unaffordable" ? 0.0 : 1_840.0
        let basePlayer = returnPlayer(
            ore: availableBefore,
            completionID: completionID,
            outcome: outcome,
            grade: grade,
            plan: plan,
            vein: vein,
            oreEarned: 0
        )
        let ore = coreOre(
            outcome: outcome,
            length: .minutes25,
            plan: plan,
            grade: grade,
            vein: vein,
            player: basePlayer,
            completionID: completionID
        )
        let player = returnPlayer(
            ore: availableBefore + ore,
            completionID: completionID,
            outcome: outcome,
            grade: grade,
            plan: plan,
            vein: vein,
            oreEarned: ore
        )
        let report = GameReturnReport(
            sessionID: returnUUID(name + "-session"),
            completionID: completionID,
            outcome: outcome,
            verificationGrade: grade,
            focusedMinutes: focusedMinutes,
            oreEarned: ore,
            vein: vein,
            veinYield: veinYield(vein),
            depthMeters: player.depthMeters,
            depthGainedMeters: depthGain(focusedMinutes: focusedMinutes, vein: vein),
            streakDays: player.streakDays,
            streakEarnedToday: focusedMinutes >= 25,
            todayFocusedMinutes: focusedMinutes,
            todayGoalMinutes: player.dailyGoalMinutes,
            completedAt: referenceDate,
            clockAssessment: .valid,
            warnings: []
        )
        return ReturnReportSeed(
            player: player,
            report: report,
            cleanupSession: cleanupSession(report: report, plan: plan)
        )
    }

    @MainActor
    static func seedReturnReportIfNeeded(
        named name: String?,
        repository: GameRepository
    ) throws {
        guard let seed = returnSeed(named: name) else { return }
        try repository.commitSession(
            player: seed.player,
            report: seed.report,
            cleanupSession: seed.cleanupSession
        )
        try repository.finishSessionCleanup(report: seed.report)
    }

    /// Deterministic stand-ins so the captured screens show the real reveal content
    /// rather than the encoder defaults.
    private static func veinYield(_ vein: VeinKind?) -> GameVeinYield? {
        switch vein {
        case .blue: .oreMultiplier(Balance.blueVeinRewardMultiplier)
        case .crystal: .crystals(Balance.crystalRegionBaseQuantity + 1)
        case .vault: .themeUnlocked
        case .resonance: .nextSessionDoubled
        case .abyss: .bonusDepth(Balance.abyssBonusDepthMeters)
        case nil: nil
        }
    }

    private static func depthGain(focusedMinutes: Int, vein: VeinKind?) -> Int {
        let credits = Double(focusedMinutes) / Balance.minutesPerFocusCredit
        let before = ProgressionEngine.depth(lifetimeFocusCredits: 12)
        let after = ProgressionEngine.depth(lifetimeFocusCredits: 12 + credits)
        let bonus = vein == .abyss ? Balance.abyssBonusDepthMeters : 0
        return max(0, after - before) + bonus
    }

    private static func returnPlayer(
        ore: Double,
        completionID: UUID,
        outcome: SessionOutcome,
        grade: VerificationGrade,
        plan: MinePlan,
        vein: VeinKind?,
        oreEarned: Double
    ) -> PlayerState {
        let completed: Bool
        if case .completed = outcome { completed = true } else { completed = false }
        let focused = completed ? 25 : 8
        let bonusDepth = vein == .abyss ? Balance.abyssBonusDepthMeters : 0
        var themes: Set<MineTheme> = [.entry, .crystal]
        if vein == .vault { themes.insert(.ruins) }
        return PlayerState(
            resources: Resources(
                ore: ore,
                crystals: vein == .crystal ? 7 : 4,
                coreShards: 0
            ),
            equipment: EquipmentLevels(drill: 4, cart: 3, lamp: 2),
            runFocusCredits: 12 + (completed ? 1 : 0),
            lifetimeFocusCredits: 12 + (completed ? 1 : 0),
            completedSessionCount: completed ? 13 : 12,
            bonusDepthMeters: bonusDepth,
            history: [SessionHistoryEntry(
                completionID: completionID,
                endedAt: referenceDate,
                focusedMinutes: focused,
                focusCredits: Double(focused) / Balance.minutesPerFocusCredit,
                plan: plan,
                verificationGrade: grade,
                oreEarned: oreEarned,
                vein: vein,
                depthAfter: 229 + bonusDepth,
                completed: completed
            )],
            appliedCompletionIDs: [completionID],
            streakDays: 7,
            unlockedThemes: themes,
            selectedTheme: .crystal,
            resonanceBoostPending: vein == .resonance,
            appliedVeinEffectIDs: vein == nil ? [] : [completionID],
            onboardingStage: .complete,
            focusProtectionPermission: .granted,
            endAlertPermission: .granted,
            returnReminderPermission: .granted,
            lastSelectedPlan: .safe,
            lastSelectedDuration: .minutes25
        )
    }

    private static func cleanupSession(
        report: GameReturnReport,
        plan: MinePlan
    ) -> PersistedGameSession {
        PersistedGameSession(
            id: report.sessionID,
            completionID: report.completionID,
            originCommandID: nil,
            length: .minutes25,
            plan: plan,
            startedAt: referenceDate.addingTimeInterval(-25 * 60),
            endsAt: referenceDate,
            clockAnchor: DeepMineCore.ClockAnchor(
                wallClock: referenceDate.addingTimeInterval(-25 * 60),
                monotonicNanoseconds: 1
            ),
            randomSeed: 13,
            phase: report.outcome == .completed ? .completed : .abandoned,
            systemsConfigured: true,
            abandonRequested: report.outcome != .completed,
            abandonSnapshot: nil,
            blockingEnabled: true,
            shieldMaintained: report.verificationGrade != .collapsed,
            forcedShieldRemoval: report.verificationGrade == .collapsed,
            forcedRemovalPending: false,
            openReason: nil,
            alarmDelivery: .none,
            liveActivityID: nil,
            warnings: []
        )
    }

    private static func returnUUID(_ value: String) -> UUID {
        let bytes = Array(value.utf8)
        let suffix = bytes.reduce(UInt64(13)) { ($0 &* 31) &+ UInt64($1) }
        return UUID(uuidString: String(
            format: "44454550-4D49-4E45-0000-%012llu", suffix % 1_000_000_000_000
        ))!
    }
}
