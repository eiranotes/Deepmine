import DeepMineCore
import Foundation

@MainActor
extension GameStore {
    func weeklyLedger() throws -> WeeklyLedger {
        WeeklyLedgerEngine.summarize(
            try repository.loadPlayer(),
            referenceDate: clock.wallNow(),
            calendar: calendar,
            timeZone: timeZone
        )
    }

    @discardableResult
    func purchaseEquipment(
        _ equipment: EquipmentKind,
        commandID: UUID = UUID()
    ) throws -> UpgradePurchaseResult {
        var player = try repository.loadPlayer()
        let result = EquipmentEngine.purchase(
            UpgradePurchaseCommand(id: commandID, equipment: equipment),
            in: &player
        )
        if case .purchased = result {
            // Level thresholds can only be crossed here, so this is where they resolve.
            AchievementEngine.evaluate(in: &player)
            try repository.savePlayer(player)
        }
        return result
    }

    func recommendedUpgrade(
        verificationGrade: VerificationGrade = .sealed
    ) throws -> UpgradeRecommendation? {
        try recommendedUpgrade(
            for: try repository.loadPlayer(),
            verificationGrade: verificationGrade
        )
    }

    /// Overload for callers that already hold the player, so rendering never triggers
    /// a redundant store read.
    func recommendedUpgrade(
        for player: PlayerState,
        verificationGrade: VerificationGrade = .sealed
    ) throws -> UpgradeRecommendation? {
        let input = try recommendationInput(
            for: player,
            verificationGrade: verificationGrade
        )
        let baselineChance = VeinEngine.chance(
            plan: input.plan,
            lampLevel: player.equipment.lamp,
            permanentResonanceLevel: player.permanentResonanceLevel,
            consecutiveMisses: 0
        )
        let protectedChance = VeinEngine.chance(
            plan: input.plan,
            lampLevel: player.equipment.lamp,
            permanentResonanceLevel: player.permanentResonanceLevel,
            consecutiveMisses: player.consecutiveVeinMisses
        )
        return try UpgradeAdvisor.recommend(
            for: player,
            nextSession: input,
            additionalVeinChance: max(0, protectedChance - baselineChance)
        )
    }

    private func recommendationInput(
        for player: PlayerState,
        verificationGrade: VerificationGrade
    ) throws -> RewardInput {
        let day = try StreakEngine.dayKey(
            for: clock.wallNow(),
            calendar: calendar,
            timeZone: timeZone
        )
        let daily = player.dailyRecords.first { $0.dayKey == day }
        return RewardInput(
            completionID: UUID(uuidString: "44454550-4D49-4E45-0000-000000000140")!,
            outcome: .completed,
            sessionLength: player.lastSelectedDuration,
            plan: player.lastSelectedPlan,
            verificationGrade: verificationGrade,
            growthFocusCredits: player.lifetimeFocusCredits,
            streakDays: player.streakDays,
            dailySessionNumber: (daily?.sessionCount ?? 0) + 1,
            equipment: player.equipment,
            vein: nil,
            resonanceBoostActive: player.resonanceBoostPending,
            startingDailyMinutes: daily?.focusedMinutes ?? 0,
            permanentUpgrades: player.permanentUpgrades
        )
    }
}
