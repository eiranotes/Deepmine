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
