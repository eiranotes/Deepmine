import DeepMineCore
import Foundation

enum DeepMineProgressLabels {
    static func equipmentKey(_ kind: EquipmentKind) -> DeepMineStringKey {
        switch kind {
        case .drill: .gameDrill
        case .cart: .gameCart
        case .lamp: .gameLamp
        }
    }

    static func equipmentEffectKey(_ kind: EquipmentKind) -> DeepMineStringKey {
        switch kind {
        case .drill: .equipmentEffectDrill
        case .cart: .equipmentEffectCart
        case .lamp: .equipmentEffectLamp
        }
    }

    static func equipmentSymbol(_ kind: EquipmentKind) -> String {
        switch kind {
        case .drill: "gearshape.2.fill"
        case .cart: "shippingbox.fill"
        case .lamp: "lightbulb.fill"
        }
    }

    static func regionKey(_ region: MineRegion) -> DeepMineStringKey {
        switch region {
        case .entry: .regionEntry
        case .crystal: .regionCrystal
        case .ruins: .regionRuins
        case .abyss: .regionAbyss
        }
    }

    static func planKey(_ plan: MinePlan) -> DeepMineStringKey {
        switch plan {
        case .safe: .gameSafePlan
        case .deep: .gameDeepPlan
        case .survey: .gameSurveyPlan
        }
    }

    static func veinKey(_ vein: VeinKind) -> DeepMineStringKey {
        switch vein {
        case .blue: .gameBlueVein
        case .crystal: .gameCrystalVein
        case .vault: .gameVaultVein
        case .resonance: .gameResonanceVein
        case .abyss: .gameAbyssVein
        }
    }

    static func date(
        _ value: Date,
        calendar: Calendar,
        timeZone: TimeZone,
        locale: Locale = .current
    ) -> String {
        value.formatted(
            Date.FormatStyle(
                date: .abbreviated,
                time: .shortened,
                locale: locale,
                calendar: calendar,
                timeZone: timeZone
            )
        )
    }
}
