import DeepMineCore
import Foundation
import OSLog

private let returnReportLogger = Logger(
    subsystem: "com.eiraworks.deepmine",
    category: "return-report"
)

struct SessionRewardProjection: Equatable, Sendable {
    let length: SessionLength
    let plan: MinePlan
    let grade: VerificationGrade
    let completedReward: RewardResult
    let abandonmentReward: RewardResult
    /// Includes the dry spell protection already earned, so the number shown is the
    /// one this session will actually roll against.
    let veinChance: Double
}

struct ReturnUpgradeRecommendation: Equatable, Hashable, Sendable {
    let equipment: EquipmentKind
    let currentLevel: Int
    let nextLevel: Int
    let cost: Double
    let availableOre: Double
    let marginalExpectedOre: Double

    var isAffordable: Bool { availableOre >= cost }
}

struct ReturnNextPromise: Equatable, Sendable {
    let currentRegion: MineRegion
    let nextRegion: MineRegion?
    let remainingDepthMeters: Int
}

struct ReturnReportPresentation: Equatable, Sendable {
    let report: GameReturnReport
    let length: SessionLength
    let plan: MinePlan
    let recommendation: ReturnUpgradeRecommendation?
    let nextPromise: ReturnNextPromise
}

enum ReturnPresentationLoadState: Equatable, Sendable {
    case ready(ReturnReportPresentation)
    case failed
}

@MainActor
extension GameStore {
    func returnPresentationState(for report: GameReturnReport) -> ReturnPresentationLoadState {
        do {
            return .ready(try returnPresentation(for: report))
        } catch {
            let errorType = String(reflecting: type(of: error))
            returnReportLogger.error("Return presentation failed: \(errorType, privacy: .public)")
            return .failed
        }
    }

    func returnPresentation(for report: GameReturnReport) throws -> ReturnReportPresentation {
        let player = try repository.loadPlayer()
        let history = player.history.first { $0.completionID == report.completionID }
        let length = history.flatMap { entry in
            SessionLength.allCases.first { $0.minutes == entry.focusedMinutes }
        } ?? player.lastSelectedDuration
        let plan = history?.plan ?? player.lastSelectedPlan
        return ReturnReportPresentation(
            report: report,
            length: length,
            plan: plan,
            recommendation: try returnRecommendation(player: player),
            nextPromise: nextPromise(depth: report.depthMeters)
        )
    }

    func resume() async throws {
        if let resumeTask {
            try await resumeTask.value
            return
        }
        let task = Task { @MainActor in try await self.performResume() }
        resumeTask = task
        defer { resumeTask = nil }
        try await task.value
    }

    func refreshSnapshot() throws -> GameStoreDiagnostic {
        activeSession = try repository.loadActiveSession()
        returnReport = try repository.loadReturnReport()
        return diagnosticSnapshot()
    }

    func rewardProjection(
        length: SessionLength,
        plan: MinePlan,
        grade: VerificationGrade,
        abandonmentMinutes: Int? = nil
    ) throws -> SessionRewardProjection {
        try rewardProjection(
            for: try repository.loadPlayer(),
            length: length,
            plan: plan,
            grade: grade,
            abandonmentMinutes: abandonmentMinutes
        )
    }

    /// Overload for callers that already hold the player, so rendering never reads the
    /// store again.
    func rewardProjection(
        for player: PlayerState,
        length: SessionLength,
        plan: MinePlan,
        grade: VerificationGrade,
        abandonmentMinutes: Int? = nil
    ) throws -> SessionRewardProjection {
        let now = clock.wallNow()
        let day = try MiningStreak.dayKey(for: now, calendar: calendar, timeZone: timeZone)
        let daily = player.dailyRecords.first { $0.dayKey == day }
        let sharedID = UUID(uuidString: "44454550-4D49-4E45-0000-000000000120")!
        let base = RewardInput(
            completionID: sharedID,
            outcome: .completed,
            sessionLength: length,
            plan: plan,
            verificationGrade: grade,
            growthFocusCredits: player.lifetimeFocusCredits,
            streakDays: player.streakDays,
            dailySessionNumber: (daily?.sessionCount ?? 0) + 1,
            equipment: player.equipment,
            vein: nil,
            resonanceBoostActive: player.resonanceBoostPending,
            permanentUpgrades: player.permanentUpgrades
        )
        let elapsed = min(length.minutes, max(0, abandonmentMinutes ?? length.minutes / 2))
        let abandoned = RewardInput(
            completionID: sharedID,
            outcome: .abandoned(elapsedMinutes: elapsed),
            sessionLength: length,
            plan: plan,
            verificationGrade: grade,
            growthFocusCredits: base.growthFocusCredits,
            streakDays: base.streakDays,
            dailySessionNumber: base.dailySessionNumber,
            equipment: base.equipment,
            vein: nil,
            resonanceBoostActive: base.resonanceBoostActive,
            permanentUpgrades: base.permanentUpgrades
        )
        return SessionRewardProjection(
            length: length,
            plan: plan,
            grade: grade,
            completedReward: try RewardCalculator.calculate(base),
            abandonmentReward: try RewardCalculator.calculate(abandoned),
            veinChance: VeinEngine.chance(
                plan: plan,
                lampLevel: player.equipment.lamp,
                permanentResonanceLevel: player.permanentResonanceLevel,
                consecutiveMisses: player.consecutiveVeinMisses
            )
        )
    }

    func activeRewardProjection() throws -> SessionRewardProjection? {
        let persisted = try repository.loadActiveSession()
        guard let session = activeSession ?? persisted else { return nil }
        let observation = ClockIntegrityChecker.finish(anchor: session.clockAnchor, source: clock)
        let elapsed = min(session.length.minutes, max(0, Int(observation.acceptedElapsed / 60)))
        let grade = currentVerificationGrade(for: session, observation: observation)
        return try rewardProjection(
            length: session.length,
            plan: session.plan,
            grade: grade,
            abandonmentMinutes: elapsed
        )
    }

    func currentVerificationGrade(for session: PersistedGameSession) -> VerificationGrade {
        currentVerificationGrade(
            for: session,
            observation: ClockIntegrityChecker.finish(anchor: session.clockAnchor, source: clock)
        )
    }

    private func currentVerificationGrade(
        for session: PersistedGameSession,
        observation: DeepMineCore.ClockObservation
    ) -> VerificationGrade {
        verificationGrade(for: session, observation: observation, at: clock.wallNow())
    }

    private func returnRecommendation(
        player: PlayerState
    ) throws -> ReturnUpgradeRecommendation? {
        let now = clock.wallNow()
        let day = try MiningStreak.dayKey(for: now, calendar: calendar, timeZone: timeZone)
        let daily = player.dailyRecords.first { $0.dayKey == day }
        let input = RewardInput(
            completionID: UUID(uuidString: "44454550-4D49-4E45-0000-000000000130")!,
            outcome: .completed,
            sessionLength: player.lastSelectedDuration,
            plan: player.lastSelectedPlan,
            verificationGrade: .sealed,
            growthFocusCredits: player.lifetimeFocusCredits,
            streakDays: player.streakDays,
            dailySessionNumber: (daily?.sessionCount ?? 0) + 1,
            equipment: player.equipment,
            vein: nil,
            resonanceBoostActive: player.resonanceBoostPending,
            permanentUpgrades: player.permanentUpgrades
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
        let marginal = try UpgradeAdvisor.marginalExpectedOre(
            for: player,
            nextSession: input,
            additionalVeinChance: max(0, protectedChance - baselineChance)
        )
        var best: ReturnUpgradeRecommendation?
        var bestEfficiency = -Double.infinity
        for equipment in EquipmentKind.allCases {
            let level = EquipmentEngine.level(of: equipment, in: player.equipment)
            guard let cost = EquipmentEngine.upgradeCost(
                for: equipment, currentLevel: level
            ), let gain = marginal[equipment], gain > 0 else { continue }
            let efficiency = gain / cost
            if efficiency > bestEfficiency {
                bestEfficiency = efficiency
                best = ReturnUpgradeRecommendation(
                    equipment: equipment,
                    currentLevel: level,
                    nextLevel: level + 1,
                    cost: cost,
                    availableOre: player.resources.ore,
                    marginalExpectedOre: gain
                )
            }
        }
        return best
    }

    private func nextPromise(depth: Int) -> ReturnNextPromise {
        let current = WorldProgression.region(forDepth: depth)
        let target: (MineRegion, Int)? = switch current {
        case .entry: (.crystal, Balance.crystalRegionDepth)
        case .crystal: (.ruins, Balance.ruinsRegionDepth)
        case .ruins: (.abyss, Balance.abyssRegionDepth)
        case .abyss: nil
        }
        return ReturnNextPromise(
            currentRegion: current,
            nextRegion: target?.0,
            remainingDepthMeters: max(0, (target?.1 ?? depth) - depth)
        )
    }
}
