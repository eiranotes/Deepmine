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
    let veinChance: Double
}

struct ReturnUpgradeRecommendation: Equatable, Hashable, Sendable {
    let equipment: EquipmentKind
    let currentLevel: Int
    let nextLevel: Int
    let cost: BigNumber
    let availableOre: BigNumber
    let marginalExpectedOre: Double

    var isAffordable: Bool { availableOre >= cost }

    func hash(into hasher: inout Hasher) {
        hasher.combine(equipment)
        hasher.combine(currentLevel)
        hasher.combine(nextLevel)
        hasher.combine(cost.mantissa)
        hasher.combine(cost.exponent)
        hasher.combine(availableOre.mantissa)
        hasher.combine(availableOre.exponent)
        hasher.combine(marginalExpectedOre)
    }
}

struct ReturnDepthGoal: Equatable, Sendable {
    let currentRegion: MineRegion
    let nextRegion: MineRegion?
    let remainingDepthMeters: Int
}

struct ReturnReportPresentation: Equatable, Sendable {
    let report: GameReturnReport
    let length: SessionLength
    let plan: MinePlan
    let recommendation: ReturnUpgradeRecommendation?
    let nextGoal: ReturnDepthGoal
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
            returnReportLogger.error(
                "Return presentation failed: \(String(reflecting: type(of: error)), privacy: .public)"
            )
            return .failed
        }
    }

    func returnPresentation(for report: GameReturnReport) throws -> ReturnReportPresentation {
        let player = try repository.loadPlayer()
        let history = player.history.first { $0.completionID == report.completionID }
        let length = history.flatMap { entry in
            SessionLength.allCases.first { $0.minutes == entry.focusedMinutes }
        } ?? player.lastSelectedDuration
        return ReturnReportPresentation(
            report: report,
            length: length,
            plan: history?.plan ?? player.lastSelectedPlan,
            recommendation: try returnRecommendation(player: player),
            nextGoal: nextDepthGoal(depth: report.depthMeters)
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
        let common = (
            growth: player.lifetimeFocusCredits,
            streak: player.streakDays,
            daily: (daily?.sessionCount ?? 0) + 1,
            equipment: player.equipment,
            resonance: player.resonanceBoostPending,
            permanent: player.permanentUpgrades
        )
        let completedInput = RewardInput(
            completionID: sharedID,
            outcome: .completed,
            sessionLength: length,
            plan: plan,
            verificationGrade: grade,
            growthFocusCredits: common.growth,
            streakDays: common.streak,
            dailySessionNumber: common.daily,
            equipment: common.equipment,
            vein: nil,
            resonanceBoostActive: common.resonance,
            permanentUpgrades: common.permanent
        )
        let elapsed = min(length.minutes, max(0, abandonmentMinutes ?? length.minutes / 2))
        let abandonedInput = RewardInput(
            completionID: sharedID,
            outcome: .abandoned(elapsedMinutes: elapsed),
            sessionLength: length,
            plan: plan,
            verificationGrade: grade,
            growthFocusCredits: common.growth,
            streakDays: common.streak,
            dailySessionNumber: common.daily,
            equipment: common.equipment,
            vein: nil,
            resonanceBoostActive: common.resonance,
            permanentUpgrades: common.permanent
        )
        return SessionRewardProjection(
            length: length,
            plan: plan,
            grade: grade,
            completedReward: try mineProjection(input: completedInput, player: player),
            abandonmentReward: try mineProjection(input: abandonedInput, player: player),
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
        return try rewardProjection(
            length: session.length,
            plan: session.plan,
            grade: currentVerificationGrade(for: session, observation: observation),
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

    private func mineProjection(input: RewardInput, player: PlayerState) throws -> RewardResult {
        let basis = try RewardCalculator.calculate(input)
        let equipment = max(1, basis.breakdown.equipment)
        let permanent = max(1, basis.breakdown.permanent)
        let rate = basis.breakdown.combinedMultiplier / equipment / permanent
        var projected = player
        let update = MiningLoop.advance(
            seconds: TimeInterval(basis.focusedMinutes * 60) * (rate.isFinite ? max(0, rate) : 0),
            in: &projected
        )
        let ore = update.oreGained.doubleValue
        return RewardResult(
            completionID: basis.completionID,
            focusedMinutes: basis.focusedMinutes,
            focusCredits: basis.focusCredits,
            ore: ore.isFinite ? max(0, ore) : Double.greatestFiniteMagnitude,
            breakdown: basis.breakdown,
            wasDuplicate: basis.wasDuplicate
        )
    }

    private func returnRecommendation(player: PlayerState) throws -> ReturnUpgradeRecommendation? {
        guard let value = UpgradeAdvisor.recommendForMining(
            for: player,
            affordableOnly: false
        ) else { return nil }
        return ReturnUpgradeRecommendation(
            equipment: value.equipment,
            currentLevel: value.currentLevel,
            nextLevel: value.nextLevel,
            cost: value.bigCost,
            availableOre: player.resources.ore,
            marginalExpectedOre: value.marginalExpectedOre
        )
    }

    private func nextDepthGoal(depth: Int) -> ReturnDepthGoal {
        let current = WorldProgression.region(forDepth: depth)
        let target: (MineRegion, Int)? = switch current {
        case .entry: (.crystal, Balance.crystalRegionDepth)
        case .crystal: (.ruins, Balance.ruinsRegionDepth)
        case .ruins: (.abyss, Balance.abyssRegionDepth)
        case .abyss: nil
        }
        return ReturnDepthGoal(
            currentRegion: current,
            nextRegion: target?.0,
            remainingDepthMeters: max(0, (target?.1 ?? depth) - depth)
        )
    }
}
