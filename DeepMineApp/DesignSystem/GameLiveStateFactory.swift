import DeepMineCore
import Foundation

extension GameFixtures {
    static func liveState(
        player: PlayerState,
        diagnostic: GameStoreDiagnostic,
        now: Date = Date()
    ) -> GameFixtureState {
        let session = diagnostic.activeSession.map { active in
            GameSessionFixture(
                id: active.id,
                length: active.length,
                plan: active.plan,
                verificationGrade: liveGrade(active),
                phase: active.phase,
                startedAt: active.startedAt,
                endsAt: active.endsAt,
                remainingSeconds: max(0, Int(active.endsAt.timeIntervalSince(now)))
            )
        }
        let report = diagnostic.returnReport.map { value in
            let history = player.history.first { $0.completionID == value.completionID }
            return GameReturnFixture(
                completionID: value.completionID,
                length: history.flatMap { entry in
                    entry.completed
                        ? SessionLength.allCases.first { $0.minutes == entry.focusedMinutes }
                        : nil
                },
                plan: history?.plan,
                outcome: value.outcome,
                verificationGrade: value.verificationGrade,
                focusedMinutes: value.focusedMinutes,
                oreEarned: value.oreEarned,
                vein: value.vein,
                depthMeters: value.depthMeters
            )
        }
        let status: DeepMineStatus
        if session != nil {
            status = .mining
        } else if let report {
            status = report.verificationGrade == .collapsed ? .failed : .completed
        } else {
            status = player.completedSessionCount == 0 ? .notStarted : .completed
        }
        return GameFixtureState(
            scenario: session == nil
                ? (player.completedSessionCount == 0 ? .fresh : .progressed)
                : .activeSealed,
            surface: .mineHome,
            referenceDate: now,
            player: player,
            session: session,
            report: report,
            status: diagnostic.visibleReason == nil ? status : .attention,
            noticeKey: diagnostic.visibleReason == nil ? nil : .stateAttention
        )
    }

    static func coreOre(
        outcome: SessionOutcome,
        length: SessionLength,
        plan: MinePlan,
        grade: VerificationGrade,
        vein: VeinKind?,
        player: PlayerState,
        completionID: UUID
    ) -> Double {
        let input = RewardInput(
            completionID: completionID,
            outcome: outcome,
            sessionLength: length,
            plan: plan,
            verificationGrade: grade,
            growthFocusCredits: player.lifetimeFocusCredits,
            streakDays: player.streakDays,
            dailySessionNumber: 1,
            equipment: player.equipment,
            vein: vein,
            resonanceBoostActive: player.resonanceBoostPending,
            startingDailyMinutes: 0,
            permanentUpgrades: player.permanentUpgrades
        )
        do {
            return try RewardCalculator.calculate(input).ore
        } catch {
            preconditionFailure("Invalid deterministic fixture input: \(error)")
        }
    }

    private static func liveGrade(_ session: PersistedGameSession) -> VerificationGrade {
        VerificationGrade.resolve(
            blockingEnabled: session.blockingEnabled,
            shieldMaintained: session.shieldMaintained,
            forcedShieldRemoval: session.forcedShieldRemoval
        )
    }
}
