import Foundation

enum DeepMineNumberFormatter {
    static func string(_ value: Double, locale: Locale = .current) -> String {
        guard value.isFinite else { return "—" }
        let korean = locale.identifier.lowercased().hasPrefix("ko")
        let magnitude = abs(value)
        let unit: (divisor: Double, key: DeepMineStringKey)?
        if korean {
            if magnitude >= 1_000_000_000_000 { unit = (1_000_000_000_000, .numberTrillion) }
            else if magnitude >= 100_000_000 { unit = (100_000_000, .numberHundredMillion) }
            else if magnitude >= 10_000 { unit = (10_000, .numberTenThousand) }
            else { unit = nil }
        } else if magnitude >= 1_000_000_000_000 { unit = (1_000_000_000_000, .numberTrillion) }
        else if magnitude >= 1_000_000_000 { unit = (1_000_000_000, .numberBillion) }
        else if magnitude >= 1_000_000 { unit = (1_000_000, .numberMillion) }
        else if magnitude >= 1_000 { unit = (1_000, .numberThousand) }
        else { unit = nil }

        let scaled = unit.map { value / $0.divisor } ?? value
        let formatted = scaled.formatted(
            .number.precision(.fractionLength(0 ... (unit == nil ? 0 : 1))).locale(locale)
        )
        guard let unit else { return formatted }
        return formatted + DeepMineStrings.text(unit.key, locale: locale)
    }
}
