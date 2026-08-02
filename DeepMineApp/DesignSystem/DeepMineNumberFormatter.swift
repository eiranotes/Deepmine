import DeepMineCore
import Foundation

enum DeepMineNumberFormatter {
    /// Unbounded growth means the wallet routinely passes the largest named unit, so the
    /// formatter falls back to scientific notation rather than printing a number nobody
    /// can read — or, worse, `—` because a `Double` conversion saturated (D-069).
    ///
    /// Korean has no everyday word above 조, so that is where the fallback starts.
    /// Deliberately not an overload of `string(_:)`. `BigNumber` is `ExpressibleBy*Literal`,
    /// so an overload makes every literal call site ambiguous — the same trap that made
    /// `Resources(ore:)` and `BigNumber`'s own comparisons ambiguous during this migration.
    static func string(big value: BigNumber, locale: Locale = .current) -> String {
        let plain = value.doubleValue
        if plain.isFinite, abs(plain) < 1e15 {
            return string(plain, locale: locale)
        }
        return value.scientificDescription
    }

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
