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
