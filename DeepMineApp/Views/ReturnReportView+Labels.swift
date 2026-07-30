import DeepMineCore
import SwiftUI

/// Player-facing vocabulary for one finished expedition.
@MainActor
extension ReturnReportView {
    var outcomeIdentifier: String {
        if case .abandoned = presentation.report.outcome { return "abandoned" }
        return "completed"
    }
    var outcomeKey: DeepMineStringKey {
        outcomeIdentifier == "abandoned" ? .returnOutcomeAbandoned : .returnOutcomeCompleted
    }
    /// Collapse, vein and clean completion each get their own figure.
    var outcomeSpriteName: String {
        if presentation.report.verificationGrade == .collapsed { return "CollapsedSprite" }
        if presentation.report.vein != nil { return "VeinSprite" }
        if case .abandoned = presentation.report.outcome { return "CollapsedSprite" }
        return "CompletedSprite"
    }

    var gradeStatus: DeepMineStatus {
        switch presentation.report.verificationGrade {
        case .sealed: .completed
        case .open: .attention
        case .collapsed: .failed
        }
    }
    var gradeKey: DeepMineStringKey {
        switch presentation.report.verificationGrade {
        case .sealed: .returnGradeSealed
        case .open: .returnGradeOpen
        case .collapsed: .returnGradeCollapsed
        }
    }

    /// The badge names the grade the session earned. It used to reuse the preparation
    /// vocabulary and read "Ready" on a finished expedition.
    var gradeBadgeKey: DeepMineStringKey {
        switch presentation.report.verificationGrade {
        case .sealed: .stateSealed
        case .open: .stateOpen
        case .collapsed: .stateCollapsed
        }
    }

    /// Names the actual yield instead of saying something was added.
    func veinEffectText(_ vein: VeinKind) -> String {
        switch presentation.report.veinYield {
        case let .crystals(quantity):
            return String(format: DeepMineStrings.text(.returnYieldCrystals), quantity)
        case let .bonusDepth(meters):
            return String(format: DeepMineStrings.text(.returnYieldDepth), meters)
        case .themeUnlocked:
            return DeepMineStrings.text(.returnYieldTheme)
        case .decorationUnlocked:
            return DeepMineStrings.text(.returnYieldDecoration)
        case .nextSessionDoubled:
            return DeepMineStrings.text(.returnYieldDoubled)
        case .oreMultiplier:
            return DeepMineStrings.text(.returnYieldOre)
        case .none:
            return DeepMineStrings.text(veinEffectKey(vein))
        }
    }

    func regionTitle(_ region: MineRegion) -> String {
        let key: DeepMineStringKey = switch region {
        case .entry: .regionEntry
        case .crystal: .regionCrystal
        case .ruins: .regionRuins
        case .abyss: .regionAbyss
        }
        return DeepMineStrings.text(key)
    }

    func equipmentTitle(_ equipment: EquipmentKind) -> String {
        let key: DeepMineStringKey = switch equipment {
        case .drill: .gameDrill
        case .cart: .gameCart
        case .lamp: .gameLamp
        }
        return DeepMineStrings.text(key)
    }

    func equipmentSymbol(_ equipment: EquipmentKind) -> String {
        switch equipment {
        case .drill: "hammer.fill"
        case .cart: "shippingbox.fill"
        case .lamp: "flashlight.on.fill"
        }
    }

    func veinTitleKey(_ vein: VeinKind) -> DeepMineStringKey {
        switch vein {
        case .blue: .gameBlueVein
        case .crystal: .gameCrystalVein
        case .vault: .gameVaultVein
        case .resonance: .gameResonanceVein
        case .abyss: .gameAbyssVein
        }
    }

    func veinEffectKey(_ vein: VeinKind) -> DeepMineStringKey {
        switch vein {
        case .blue: .returnVeinBlueEffect
        case .crystal: .returnVeinCrystalEffect
        case .vault: .returnVeinVaultEffect
        case .resonance: .returnVeinResonanceEffect
        case .abyss: .returnVeinAbyssEffect
        }
    }

    func veinSymbol(_ vein: VeinKind) -> String {
        switch vein {
        case .blue: "sparkles"
        case .crystal: "diamond.fill"
        case .vault: "lock.open.fill"
        case .resonance: "waveform.path.ecg"
        case .abyss: "arrow.down.to.line.compact"
        }
    }
}
