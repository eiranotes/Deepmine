import Foundation

/// A normalized mantissa/exponent number for quantities that compound past what
/// `Double` can render honestly.
///
/// `Double` holds magnitudes up to ~1e308, so range is not the problem. The problem is
/// that an idle economy multiplies small ratios millions of times: `1.02` applied 40,000
/// times is 1e344, and long before that the decimal string a player reads stops carrying
/// meaning. Keeping the exponent as an `Int` separates "how big" from "how precise",
/// which is what the display layer actually needs.
///
/// Invariant: `mantissa` is zero, or its magnitude lies in `[1, 10)`.
public struct BigNumber: Codable, Equatable, Comparable, Sendable {
    public private(set) var mantissa: Double
    public private(set) var exponent: Int

    public static let zero = BigNumber(mantissa: 0, exponent: 0)
    public static let one = BigNumber(1)

    /// Beyond this gap the smaller addend cannot change the larger one's representable
    /// digits, so alignment is skipped rather than silently rounded away.
    private static let significantDigitSpan = 17

    public init(_ value: Double) {
        self.init(mantissa: value, exponent: 0)
    }

    public init(mantissa: Double, exponent: Int) {
        guard mantissa.isFinite, mantissa != 0 else {
            self.mantissa = 0
            self.exponent = 0
            return
        }
        let magnitude = abs(mantissa)
        let shift = Int(floor(log10(magnitude)))
        let scaled = mantissa / pow(10, Double(shift))
        // log10 rounding at decade boundaries can land just outside [1, 10).
        if abs(scaled) >= 10 {
            self.mantissa = scaled / 10
            self.exponent = exponent + shift + 1
        } else if abs(scaled) < 1 {
            self.mantissa = scaled * 10
            self.exponent = exponent + shift - 1
        } else {
            self.mantissa = scaled
            self.exponent = exponent + shift
        }
    }

    public var isZero: Bool { mantissa == 0 }

    public var isNegative: Bool { mantissa < 0 }

    /// Collapses back to `Double`. Saturates rather than trapping, because a caller
    /// asking for a `Double` wants a number to draw, not a crash.
    public var doubleValue: Double {
        guard !isZero else { return 0 }
        if exponent > 308 { return mantissa < 0 ? -.greatestFiniteMagnitude : .greatestFiniteMagnitude }
        if exponent < -308 { return 0 }
        return mantissa * pow(10, Double(exponent))
    }

    /// Base-10 logarithm, defined for positive values. The ordering key for progression
    /// curves, which care about magnitude rather than value.
    public var log10Value: Double? {
        guard mantissa > 0 else { return nil }
        return Double(exponent) + log10(mantissa)
    }
}

// MARK: - Arithmetic

extension BigNumber {
    public static func + (lhs: Self, rhs: Self) -> Self {
        if lhs.isZero { return rhs }
        if rhs.isZero { return lhs }
        let (larger, smaller) = lhs.exponent >= rhs.exponent ? (lhs, rhs) : (rhs, lhs)
        let gap = larger.exponent - smaller.exponent
        guard gap < significantDigitSpan else { return larger }
        let aligned = smaller.mantissa / pow(10, Double(gap))
        return BigNumber(mantissa: larger.mantissa + aligned, exponent: larger.exponent)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        lhs + rhs.negated
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        guard !lhs.isZero, !rhs.isZero else { return .zero }
        return BigNumber(mantissa: lhs.mantissa * rhs.mantissa, exponent: lhs.exponent + rhs.exponent)
    }

    public static func / (lhs: Self, rhs: Self) -> Self {
        guard !rhs.isZero else { return .zero }
        guard !lhs.isZero else { return .zero }
        return BigNumber(mantissa: lhs.mantissa / rhs.mantissa, exponent: lhs.exponent - rhs.exponent)
    }

    public static func * (lhs: Self, rhs: Double) -> Self {
        lhs * BigNumber(rhs)
    }

    public static func / (lhs: Self, rhs: Double) -> Self {
        lhs / BigNumber(rhs)
    }

    /// Mixed arithmetic with `Double`, one-sided on purpose.
    ///
    /// Overloads taking `Double` on the *left* are not defined, and must not be: this
    /// type's own initialiser compares `abs(scaled) < 1`, and an integer literal there
    /// would then resolve to `BigNumber` rather than `Double`, calling the initialiser
    /// again. That recursion overflows the stack on the first value constructed.
    ///
    /// Mixed arithmetic with `Double`.
    ///
    /// Prices, costs and rewards are still ordinary numbers — a drill costs 100, not
    /// 1.0e2 — and the wallet is the only value that has to survive unbounded growth
    /// (D-069). Keeping these overloads means the economy reads the same as before
    /// instead of wrapping every literal at the call site.
    public static func + (lhs: Self, rhs: Double) -> Self { lhs + BigNumber(rhs) }
    public static func - (lhs: Self, rhs: Double) -> Self { lhs - BigNumber(rhs) }
    public static func += (lhs: inout Self, rhs: Double) { lhs = lhs + rhs }
    public static func -= (lhs: inout Self, rhs: Double) { lhs = lhs - rhs }

    public static func < (lhs: Self, rhs: Double) -> Bool { lhs < BigNumber(rhs) }
    public static func > (lhs: Self, rhs: Double) -> Bool { lhs > BigNumber(rhs) }
    public static func <= (lhs: Self, rhs: Double) -> Bool { lhs <= BigNumber(rhs) }
    public static func >= (lhs: Self, rhs: Double) -> Bool { lhs >= BigNumber(rhs) }

    /// Always true: a `BigNumber` cannot be infinite or NaN by construction, which is the
    /// property the wallet was migrated to get.
    public var isFinite: Bool { true }

    public static func += (lhs: inout Self, rhs: Self) { lhs = lhs + rhs }
    public static func -= (lhs: inout Self, rhs: Self) { lhs = lhs - rhs }
    public static func *= (lhs: inout Self, rhs: Self) { lhs = lhs * rhs }
    public static func *= (lhs: inout Self, rhs: Double) { lhs = lhs * rhs }

    public var negated: Self {
        BigNumber(mantissa: -mantissa, exponent: exponent)
    }

    /// Raises to a real power without going through `Double`, so the result survives
    /// exponents `Double` would overflow. This is the operation compounding needs.
    public func raised(to power: Double) -> Self {
        guard let log = log10Value else { return .zero }
        let resultLog = log * power
        guard resultLog.isFinite else {
            return resultLog < 0 ? .zero : Self(mantissa: 1, exponent: Self.exponentLimit)
        }
        let wholePart = floor(resultLog)
        // `Int(wholePart)` traps once the exponent leaves `Int`'s range, which unbounded
        // compounding reaches. Clamping the exponent keeps the number a number: the value
        // is already beyond anything the game compares against (D-069).
        guard abs(wholePart) < Double(Self.exponentLimit) else {
            return wholePart < 0 ? .zero : Self(mantissa: 1, exponent: Self.exponentLimit)
        }
        let fraction = resultLog - wholePart
        return BigNumber(mantissa: pow(10, fraction), exponent: Int(wholePart))
    }

    /// Far past any quantity the game produces, and small enough that exponent arithmetic
    /// cannot overflow `Int` by adding two of them.
    static let exponentLimit = 1_000_000_000

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.isZero || rhs.isZero || (lhs.isNegative != rhs.isNegative) {
            return lhs.doubleValueForOrdering < rhs.doubleValueForOrdering
        }
        if lhs.exponent != rhs.exponent {
            return lhs.isNegative ? lhs.exponent > rhs.exponent : lhs.exponent < rhs.exponent
        }
        return lhs.mantissa < rhs.mantissa
    }

    /// Sign-only collapse used for the mixed-sign and zero comparison cases, where the
    /// exponent alone cannot order the pair.
    private var doubleValueForOrdering: Double {
        guard !isZero else { return 0 }
        return mantissa < 0 ? -1 : 1
    }
}

// MARK: - Notation

extension BigNumber {
    /// The pieces a display formatter needs, without deciding any locale policy here.
    /// Localized abbreviation belongs in the app layer.
    public struct Notation: Equatable, Sendable {
        public let mantissa: Double
        public let exponent: Int
        /// Exponent rounded down to a multiple of three, the grouping every unit system
        /// (thousand/million, and the K/M/B suffixes) is built on.
        public let engineeringExponent: Int
        public let engineeringMantissa: Double

        public init(mantissa: Double, exponent: Int) {
            self.mantissa = mantissa
            self.exponent = exponent
            let grouped = Int(floor(Double(exponent) / 3)) * 3
            engineeringExponent = grouped
            engineeringMantissa = mantissa * pow(10, Double(exponent - grouped))
        }
    }

    public var notation: Notation {
        Notation(mantissa: mantissa, exponent: exponent)
    }

    /// Stable, locale-independent rendering for tests, logs and the balance CLI.
    public var scientificDescription: String {
        guard !isZero else { return "0" }
        return String(format: "%.3fe%d", mantissa, exponent)
    }
}

extension BigNumber: CustomStringConvertible {
    public var description: String { scientificDescription }
}

extension BigNumber: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(Double(value))
    }
}

extension BigNumber: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}
