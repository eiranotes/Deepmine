import DeepMineCore
import SwiftUI

enum HomeMiningClockPolicy {
    static func isLive(
        isFixture: Bool,
        isSessionRecoveryComplete: Bool,
        isSessionStartInFlight: Bool,
        hasActiveSession: Bool
    ) -> Bool {
        !isFixture
            && isSessionRecoveryComplete
            && !isSessionStartInFlight
            && !hasActiveSession
    }
}

/// Navigation and store actions behind the root scene.
@MainActor
extension GameRootView {
    /// Visible automation and offline catch-up are one economic clock. Keeping their
    /// gate identical prevents a focus session from being paid here and again at return.
    var isHomeMiningClockLive: Bool {
        HomeMiningClockPolicy.isLive(
            isFixture: fixtureState != nil,
            isSessionRecoveryComplete: isSessionRecoveryComplete,
            isSessionStartInFlight: isSessionStartInFlight,
            hasActiveSession: gameStore?.activeSession != nil
        )
    }

    /// Recomputed only when the player changes. Deriving it inside `body` re-read the
    /// repository on every pass, which is both wasted I/O and a visible side effect.
    func refreshRecommendation() {
        guard let gameStore else { return }
        homeRecommendation = gameStore.recommendedUpgrade(for: player)
        homeProjectedOre = try? gameStore.rewardProjection(
            for: player,
            length: player.lastSelectedDuration,
            plan: player.lastSelectedPlan,
            grade: .sealed
        ).completedReward.ore
    }

    func purchase(equipment: EquipmentKind) {
        guard let gameStore else { return }
        guard let result = try? gameStore.purchaseEquipment(equipment) else { return }
        guard case let .purchased(_, newLevel, _) = result else { return }
        let crewStepped = equipment == .drill
            && MineCrew.size(drillLevel: newLevel) > MineCrew.size(drillLevel: newLevel - 1)
        feedback.play(crewStepped ? .crewGrew : .upgradeInstalled)
        refreshLivePlayer()
    }

    func select(plan: MinePlan) {
        if let gameStore {
            guard let updated = try? gameStore.select(plan: plan) else { return }
            player = updated
        } else {
            var updated = player
            OnboardingEngine.select(plan: plan, in: &updated)
            player = updated
        }
    }

    func openSettings() {
        savedGoalMinutes = nil
        path.append(.settings)
    }

    func select(duration: SessionLength) {
        if let gameStore {
            guard let updated = try? gameStore.select(duration: duration) else { return }
            player = updated
        } else {
            var updated = player
            OnboardingEngine.select(duration: duration, in: &updated)
            player = updated
        }
    }

    func refreshLivePlayer() {
        guard let repository, let loaded = try? repository.load() else { return }
        player = loaded
        refreshRecommendation()
    }

    func recoverSession() async -> Bool {
        guard let gameStore else { return false }
        do {
            try await gameStore.resume()
        } catch {
            return false
        }
        refreshLivePlayer()
        if gameStore.activeSession != nil, path.last != .activeMine {
            path.append(.activeMine)
        } else if let report = gameStore.returnReport,
                  !feedback.isDismissed(completionID: report.completionID),
                  path.isEmpty {
            path.append(.returnReport)
        }
        return true
    }

    func receive(_ report: GameReturnReport) {
        if let loaded = try? gameStore?.playerState() { player = loaded }
        path = [.returnReport]
    }

    func closeReport(_ report: GameReturnReport) {
        feedback.markDismissed(completionID: report.completionID)
        refreshLivePlayer()
        path = []
        Task { @MainActor in
            try? await gameStore?.dismissReturnReport()
        }
    }

    func prepareNext(
        _ recommendation: ReturnUpgradeRecommendation?,
        report: GameReturnReport
    ) {
        feedback.markDismissed(completionID: report.completionID)
        path = [.equipment(recommendation)]
        Task { @MainActor in
            try? await gameStore?.dismissReturnReport()
        }
    }

    var progressReferenceDate: Date { gameStore?.clock.wallNow() ?? fixtureState?.referenceDate ?? Date() }
    var progressCalendar: Calendar { gameStore?.calendar ?? Calendar.current }
    var progressTimeZone: TimeZone { gameStore?.timeZone ?? TimeZone.current }

    var returnReportRecovery: some View {
        ReturnReportRecoveryView { path = [] }
    }
}
