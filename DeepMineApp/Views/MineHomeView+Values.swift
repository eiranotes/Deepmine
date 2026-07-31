import DeepMineCore
import Foundation

/// Values the mine control scene derives from player state.
extension MineHomeView {
    var todayMinutes: Int {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        guard let year = components.year,
              let month = components.month,
              let day = components.day else { return 0 }
        let today = DayKey(year: year, month: month, day: day)
        return player.dailyRecords.first { $0.dayKey == today }?.focusedMinutes ?? 0
    }

    var nextSteps: [NextStep] {
        NextStepPlanner.steps(for: player, expectedOrePerSession: expectedOrePerSession)
    }

    /// Only used to turn an ore shortfall into "about N more expeditions". Nil-safe: the
    /// planner withholds the estimate rather than guessing when this is unavailable.
    private var expectedOrePerSession: Double {
        projectedOrePerSession ?? 0
    }


    func stepTitle(_ step: NextStep) -> String {
        switch step.kind {
        case .equipment:
            let kind = EquipmentKind(rawValue: step.detail ?? "") ?? .drill
            return "\(equipmentTitle(kind)) Lv.\(EquipmentEngine.level(of: kind, in: player.equipment) + 1)"
        case .region:
            let region = MineRegion(rawValue: step.detail ?? "") ?? .crystal
            return DeepMineStrings.text(DeepMineProgressLabels.regionKey(region))
        case .streak:
            return "\(DeepMineStrings.text(.homeStreakActive)) \(step.target)\(DeepMineStrings.text(.gameDays))"
        case .crew:
            return String(format: DeepMineStrings.text(.homeStepCrew), step.detail ?? "")
        }
    }

    func stepDetail(_ step: NextStep) -> String {
        switch step.kind {
        case .equipment:
            guard let sessions = step.remainingSessions else {
                return DeepMineNumberFormatter.string(Double(step.target - step.current))
            }
            return sessions == 0
                ? DeepMineStrings.text(.homeStepReady)
                : String(format: DeepMineStrings.text(.homeStepSessions), sessions)
        case .region:
            return "\(max(0, step.target - step.current))m"
        case .streak:
            return String(
                format: DeepMineStrings.text(.homeStepDays),
                max(0, step.target - step.current)
            )
        case .crew:
            return "Lv.\(step.target)"
        }
    }

    var nextPromiseText: String {
        if player.completedSessionCount == 0 {
            return DeepMineStrings.text(.homeNextFresh)
        }
        if !player.isDeepMiningUnlocked {
            let remaining = Balance.deepUnlockCompletedSessions - player.completedSessionCount
            return "\(remaining) \(DeepMineStrings.text(.homeNextProgressed))"
        }
        return DeepMineStrings.text(.homeNextDeepReady)
    }

    var depthResources: String {
        "\(DeepMineStrings.text(.gameCrystals)) \(player.resources.crystals) · "
            + "\(DeepMineStrings.text(.gameCoreShards)) \(player.resources.coreShards)"
    }

    var planDetailKey: DeepMineStringKey {
        switch player.lastSelectedPlan {
        case .safe: .homePlanDetailSafe
        case .deep: .homePlanDetailDeep
        case .survey: .homePlanDetailSurvey
        }
    }


    var isEquipmentDepthLocked: Bool {
        let unlocked = player.unlockedEquipmentLevel
        return EquipmentKind.allCases.allSatisfy {
            EquipmentEngine.level(of: $0, in: player.equipment) >= unlocked
        }
    }

    func equipmentTitle(_ equipment: EquipmentKind) -> String {
        let key: DeepMineStringKey = switch equipment {
        case .drill: .gameDrill
        case .cart: .gameCart
        case .lamp: .gameLamp
        }
        return DeepMineStrings.text(key)
    }
}
