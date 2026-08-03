import DeepMineCore
import Foundation

/// Compact, range-safe formatting for production rates and before/after feedback.
/// Unlike the wallet formatter, rates below one must retain their significant digits.
enum DeepMineRateFormatter {
    static func string(_ value: BigNumber, locale: Locale = .current) -> String {
        guard !value.isZero else { return DeepMineNumberFormatter.string(0, locale: locale) }
        let notation = value.notation
        if notation.exponent >= -2, notation.exponent < 3 {
            return value.doubleValue.formatted(
                .number.precision(.significantDigits(2 ... 3)).locale(locale)
            )
        }
        if notation.exponent >= 3, notation.exponent < 15 {
            return DeepMineNumberFormatter.string(big: value, locale: locale)
        }
        let mantissa = notation.mantissa.formatted(
            .number.precision(.fractionLength(0 ... 2)).locale(locale)
        )
        return "\(mantissa)e\(notation.exponent)"
    }
}

struct PurchaseImpactPresentation: Equatable {
    let label: String
    let beforeValue: String
    let afterValue: String
    let changeValue: String

    init(_ impact: PurchaseImpact, locale: Locale = .current) {
        switch impact.metric {
        case let .automaticETA(before, after):
            label = DeepMineStrings.text(.equipmentImpactETA, locale: locale)
            beforeValue = DeepMineDurationFormatter.short(before, locale: locale)
            afterValue = DeepMineDurationFormatter.short(after, locale: locale)
        case let .tapOutput(before, after):
            label = DeepMineStrings.text(.equipmentImpactTap, locale: locale)
            beforeValue = DeepMineRateFormatter.string(before, locale: locale)
            afterValue = DeepMineRateFormatter.string(after, locale: locale)
        case let .automaticOutput(before, after):
            label = DeepMineStrings.text(.equipmentImpactAutomatic, locale: locale)
            beforeValue = before.map { DeepMineRateFormatter.string($0, locale: locale) }
                ?? DeepMineStrings.text(.shaftRateManual, locale: locale)
            afterValue = DeepMineRateFormatter.string(after, locale: locale)
        }

        if let gain = impact.relativeIncrease {
            changeValue = "+\(DeepMineRateFormatter.string(gain * 100, locale: locale))%"
        } else {
            changeValue = DeepMineStrings.text(.equipmentImpactStarted, locale: locale)
        }
    }

    var transition: String { "\(label)  \(beforeValue) → \(afterValue)" }
}

/// Mirrors the web-first rig installation contract. A successful purchase names the
/// exact piece of hardware that appeared, not only its production percentage.
struct RigUpgradePhysicalPresentation: Equatable {
    let visual: RigToolVisualState
    let detail: String

    init(equipment: EquipmentKind, before: PlayerState, after: PlayerState) {
        let beforeLevel = EquipmentEngine.level(of: equipment, in: before.equipment)
        let afterLevel = EquipmentEngine.level(of: equipment, in: after.equipment)
        let beforeVisual = MineInfrastructureEngine.visualState(level: beforeLevel)
        let afterVisual = MineInfrastructureEngine.visualState(level: afterLevel)
        visual = afterVisual

        if let module = after.equipmentModifications.selected(for: equipment),
           module != before.equipmentModifications.selected(for: equipment) {
            detail = module.rigDisplayName
            return
        }

        let code: String = switch equipment {
        case .drill: "D"
        case .cart: "C"
        case .lamp: "L"
        }
        let prefix = "\(code)\(afterVisual.level)"
        if afterVisual.generation != beforeVisual.generation {
            detail = "\(prefix) · G\(afterVisual.generation) · "
                + "\(afterVisual.housingVariant)형 하우징 교체"
        } else if afterVisual.artTier != beforeVisual.artTier {
            detail = "\(prefix) · T\(beforeVisual.artTier)→T\(afterVisual.artTier) 본체 교체 · "
                + "정비 셀 \(afterVisual.upgradeCells)/\(Balance.rigUpgradeCellsPerGeneration)"
        } else {
            detail = "\(prefix) · 정비 셀 \(beforeVisual.upgradeCells)→"
                + "\(afterVisual.upgradeCells)/\(Balance.rigUpgradeCellsPerGeneration) 증설"
        }
    }
}
