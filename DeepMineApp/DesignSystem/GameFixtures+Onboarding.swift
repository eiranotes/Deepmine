import DeepMineCore
import Foundation

extension GameFixtures {
    static var onboardingDemoActive: GameFixtureState {
        let player = PlayerState(
            onboardingStage: .demo,
            demoStartedAt: referenceDate
        )
        return GameFixtureState(
            scenario: .demoActive,
            surface: .onboarding,
            referenceDate: referenceDate,
            player: player,
            session: nil,
            report: nil,
            status: .mining,
            noticeKey: nil
        )
    }

    static var onboardingDemoCompleted: GameFixtureState {
        let rewardID = UUID(uuidString: "44454550-4D49-4E45-0000-000000000090")!
        let player = PlayerState(
            resources: Resources(ore: Balance.demoOreGrant),
            onboardingStage: .demoReward,
            demoStartedAt: referenceDate.addingTimeInterval(-Balance.demoDurationSeconds),
            demoCompletedAt: referenceDate,
            demoRewardReceiptID: rewardID
        )
        return GameFixtureState(
            scenario: .demoCompleted,
            surface: .onboarding,
            referenceDate: referenceDate,
            player: player,
            session: nil,
            report: nil,
            status: .completed,
            noticeKey: nil
        )
    }

    static func onboardingPlayer(for scenario: GameFixtureScenario) -> PlayerState {
        switch scenario {
        case .demoActive: onboardingDemoActive.player
        case .demoCompleted: onboardingDemoCompleted.player
        default: fixture(scenario).player
        }
    }

    static func returningPlayer(completedSessions: Int = 0) -> PlayerState {
        let progressed = completedSessions > 0
        return PlayerState(
            resources: Resources(
                ore: progressed ? 1_840 : 0,
                crystals: progressed ? 4 : 0,
                coreShards: 0
            ),
            equipment: progressed
                ? EquipmentLevels(drill: 4, cart: 3, lamp: 2)
                : EquipmentLevels(drill: 2),
            runFocusCredits: progressed ? 12 : 0,
            lifetimeFocusCredits: progressed ? 12 : 0,
            completedSessionCount: completedSessions,
            streakDays: progressed ? 7 : 0,
            onboardingStage: .complete
        )
    }
}
