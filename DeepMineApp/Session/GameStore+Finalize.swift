import DeepMineCore
import Foundation

private struct GameOutcomeContext {
    let outcome: SessionOutcome
    let grade: VerificationGrade
    let completedAt: Date
    let clockAssessment: DeepMineCore.ClockIntegrityAssessment
}

@MainActor
extension GameStore {
    func finalize(
        session: PersistedGameSession,
        completed: Bool
    ) async throws -> GameReturnReport {
        if let report = try repository.loadReturnReport(),
           report.completionID == session.completionID {
            if session.phase == .completed || session.phase == .abandoned {
                return try await finishCleanup(session: session, report: report)
            }
            returnReport = report
            return report
        }

        var player = try repository.loadPlayer()
        let context = outcomeContext(for: session, completed: completed)
        let vein = rollVein(for: session, context: context, player: &player)
        let depthBefore = player.depthMeters
        let input = try rewardInput(
            for: session,
            context: context,
            vein: vein,
            player: player
        )
        let projectedReward = try RewardCalculator.calculate(input)

        // A focus session now advances the same rock face as taps, foreground automation
        // and offline settlement. Session multipliers scale credited mining time; the
        // equipment multiplier is excluded because `MiningLoop` already reads the actual
        // drill, cart, lamp, modifications and refinement from the player.
        let creditedSeconds = TimeInterval(projectedReward.focusedMinutes * 60)
            * sessionMiningRate(projectedReward)
        let miningUpdate = creditedSeconds > 0
            ? MiningLoop.advance(
                seconds: creditedSeconds,
                at: context.completedAt,
                in: &player
            )
            : .empty(face: player.mineFace)
        let minedOre = miningUpdate.oreGained.doubleValue
        let reward = RewardResult(
            completionID: projectedReward.completionID,
            focusedMinutes: projectedReward.focusedMinutes,
            focusCredits: projectedReward.focusCredits,
            ore: minedOre.isFinite ? max(0, minedOre) : Double.greatestFiniteMagnitude,
            breakdown: projectedReward.breakdown,
            wasDuplicate: projectedReward.wasDuplicate
        )
        let applied = try ProgressionEngine.apply(
            reward: reward,
            input: input,
            completedAt: context.completedAt,
            creditOre: false,
            to: &player
        )

        var yield: GameVeinYield?
        var streakEarnedToday = false
        var earnedAchievements: [String] = []
        if applied == .applied {
            let streak = try MiningStreak.record(
                at: context.completedAt,
                in: &player,
                calendar: calendar,
                timeZone: timeZone
            )
            streakEarnedToday = streak.grewToday
            if case .completed = context.outcome {
                _ = WorldProgression.consumeResonanceBoost(in: &player)
            }
            if let vein {
                yield = Self.yield(of: WorldProgression.apply(
                    vein: vein,
                    effectID: session.completionID,
                    regionIndex: WorldProgression.region(forDepth: player.depthMeters).index,
                    to: &player
                ))
            }
            _ = WorldProgression.unlockThemesForCurrentDepth(in: &player)
            earnedAchievements = AchievementEngine.evaluate(in: &player)
                .map(\.definition.id)
        }

        let today = try MiningStreak.dayKey(
            for: context.completedAt,
            calendar: calendar,
            timeZone: timeZone
        )
        let dailyRecord = player.dailyRecords.first { $0.dayKey == today }
        let report = GameReturnReport(
            sessionID: session.id,
            completionID: session.completionID,
            outcome: context.outcome,
            verificationGrade: context.grade,
            focusedMinutes: reward.focusedMinutes,
            oreEarned: reward.ore,
            vein: vein,
            veinYield: yield,
            depthMeters: player.depthMeters,
            depthGainedMeters: max(0, player.depthMeters - depthBefore),
            streakDays: player.streakDays,
            streakEarnedToday: streakEarnedToday,
            todayFocusedMinutes: dailyRecord?.focusedMinutes ?? reward.focusedMinutes,
            todayGoalMinutes: player.dailyGoalMinutes,
            earnedAchievementIDs: earnedAchievements,
            completedAt: context.completedAt,
            clockAssessment: context.clockAssessment,
            warnings: session.warnings
        )

        var cleanupSession = session
        cleanupSession.phase = completed ? .completed : .abandoned
        try repository.commitSession(
            player: player,
            report: report,
            cleanupSession: cleanupSession
        )
        activeSession = cleanupSession
        returnReport = report
        return try await finishCleanup(session: cleanupSession, report: report)
    }

    private func sessionMiningRate(_ reward: RewardResult) -> Double {
        let equipment = max(1, reward.breakdown.equipment)
        let vein = max(1, reward.breakdown.vein)
        let rate = reward.breakdown.combinedMultiplier / equipment / vein
        return rate.isFinite ? max(0, rate) : Double.greatestFiniteMagnitude
    }

    private func outcomeContext(
        for session: PersistedGameSession,
        completed: Bool
    ) -> GameOutcomeContext {
        let observation = ClockIntegrityChecker.finish(
            anchor: session.clockAnchor,
            source: clock
        )
        let snapshot = completed ? nil : session.abandonSnapshot
        let completedAt = snapshot?.requestedAt ?? clock.wallNow()
        let grade = snapshot?.verificationGrade ?? verificationGrade(
            for: session,
            observation: observation,
            at: completedAt
        )
        let elapsed = snapshot?.elapsedMinutes ?? min(
            session.length.minutes,
            max(0, Int(observation.acceptedElapsed / 60))
        )
        return GameOutcomeContext(
            outcome: completed ? .completed : .abandoned(elapsedMinutes: elapsed),
            grade: grade,
            completedAt: completedAt,
            clockAssessment: snapshot?.clockAssessment ?? observation.assessment
        )
    }

    private func rollVein(
        for session: PersistedGameSession,
        context: GameOutcomeContext,
        player: inout PlayerState
    ) -> VeinKind? {
        var generator = SeededGenerator(seed: session.randomSeed)
        let eligible: SessionOutcome = context.grade == .collapsed
            ? .abandoned(elapsedMinutes: 0)
            : context.outcome
        return VeinEngine.rollAfterCompletion(
            outcome: eligible,
            plan: session.plan,
            state: &player,
            using: &generator
        ).vein
    }

    private func rewardInput(
        for session: PersistedGameSession,
        context: GameOutcomeContext,
        vein: VeinKind?,
        player: PlayerState
    ) throws -> RewardInput {
        let day = try MiningStreak.dayKey(
            for: context.completedAt,
            calendar: calendar,
            timeZone: timeZone
        )
        let daily = player.dailyRecords.first { $0.dayKey == day }
        return RewardInput(
            completionID: session.completionID,
            outcome: context.outcome,
            sessionLength: session.length,
            plan: session.plan,
            verificationGrade: context.grade,
            growthFocusCredits: player.lifetimeFocusCredits,
            streakDays: player.streakDays,
            dailySessionNumber: (daily?.sessionCount ?? 0) + 1,
            equipment: player.equipment,
            vein: vein,
            resonanceBoostActive: player.resonanceBoostPending,
            permanentUpgrades: player.permanentUpgrades
        )
    }

    private static func yield(of result: VeinEffectResult) -> GameVeinYield? {
        switch result {
        case let .oreMultiplier(value): .oreMultiplier(value)
        case let .crystals(quantity): .crystals(quantity)
        case let .vaultConvertedToCrystals(quantity): .crystals(quantity)
        case .themeUnlocked: .themeUnlocked
        case .decorationUnlocked: .decorationUnlocked
        case .resonanceArmed: .nextSessionDoubled
        case let .bonusDepth(meters): .bonusDepth(meters)
        case let .bonusOre(amount): .oreMultiplier(amount)
        case .duplicate: nil
        }
    }
}
