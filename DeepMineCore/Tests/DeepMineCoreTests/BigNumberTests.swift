import XCTest
@testable import DeepMineCore

final class BigNumberTests: XCTestCase {
    func testNormalizesMantissaIntoRange() {
        let value = BigNumber(12_345)
        XCTAssertEqual(value.mantissa, 1.2345, accuracy: 1e-12)
        XCTAssertEqual(value.exponent, 4)
    }

    func testNormalizesExactDecadeBoundary() {
        for exponent in -12...12 {
            let value = BigNumber(pow(10, Double(exponent)))
            XCTAssertEqual(value.mantissa, 1, accuracy: 1e-9, "10^\(exponent)")
            XCTAssertEqual(value.exponent, exponent, "10^\(exponent)")
        }
    }

    func testZeroStaysCanonical() {
        XCTAssertTrue(BigNumber(0).isZero)
        XCTAssertEqual(BigNumber(0).exponent, 0)
        XCTAssertEqual(BigNumber(0) + BigNumber(0), .zero)
    }

    func testAdditionAlignsExponents() {
        let sum = BigNumber(1_000) + BigNumber(23)
        XCTAssertEqual(sum.doubleValue, 1_023, accuracy: 1e-9)
    }

    func testAdditionIgnoresAddendBelowSignificance() {
        let large = BigNumber(mantissa: 1, exponent: 40)
        let sum = large + BigNumber(1)
        XCTAssertEqual(sum, large)
    }

    func testSubtractionToZero() {
        let value = BigNumber(500)
        XCTAssertTrue((value - value).isZero)
    }

    func testMultiplicationAddsExponents() {
        let product = BigNumber(mantissa: 2, exponent: 30) * BigNumber(mantissa: 4, exponent: 20)
        XCTAssertEqual(product.mantissa, 8, accuracy: 1e-9)
        XCTAssertEqual(product.exponent, 50)
    }

    func testDivisionByZeroYieldsZeroRatherThanInfinity() {
        XCTAssertTrue((BigNumber(10) / BigNumber.zero).isZero)
    }

    /// The operation the whole idle economy rests on: a small ratio applied tens of
    /// thousands of times, at a magnitude `Double` cannot represent at all.
    func testCompoundingBeyondDoubleRange() {
        let value = BigNumber(1.02).raised(to: 40_000)
        XCTAssertEqual(value.exponent, 344)
        XCTAssertTrue(value.doubleValue.isFinite)
    }

    func testRaisedMatchesDoubleInSafeRange() {
        let expected = pow(1.5 as Double, 20 as Double)
        let actual = BigNumber(1.5).raised(to: 20).doubleValue
        XCTAssertEqual(actual, expected, accuracy: expected * 1e-9)
    }

    func testComparisonAcrossMagnitudes() {
        XCTAssertLessThan(BigNumber(mantissa: 9, exponent: 10), BigNumber(mantissa: 1, exponent: 11))
        XCTAssertLessThan(BigNumber.zero, BigNumber(1))
        XCTAssertLessThan(BigNumber(-1), BigNumber.zero)
        XCTAssertLessThan(BigNumber(-1), BigNumber(1))
    }

    func testNegativeOrderingIsNotInverted() {
        let small = BigNumber(mantissa: -1, exponent: 3)
        let large = BigNumber(mantissa: -1, exponent: 6)
        XCTAssertLessThan(large, small)
    }

    func testEngineeringNotationGroupsByThree() {
        let notation = BigNumber(1_234_567).notation
        XCTAssertEqual(notation.engineeringExponent, 6)
        XCTAssertEqual(notation.engineeringMantissa, 1.234567, accuracy: 1e-9)
    }

    func testEngineeringNotationHandlesUngroupedExponent() {
        let notation = BigNumber(mantissa: 5, exponent: 7).notation
        XCTAssertEqual(notation.engineeringExponent, 6)
        XCTAssertEqual(notation.engineeringMantissa, 50, accuracy: 1e-9)
    }

    func testDoubleValueSaturatesInsteadOfReturningInfinity() {
        let huge = BigNumber(mantissa: 1, exponent: 400)
        XCTAssertEqual(huge.doubleValue, .greatestFiniteMagnitude)
        XCTAssertFalse(huge.doubleValue.isInfinite)
    }

    func testRoundTripsThroughCodable() throws {
        let value = BigNumber(mantissa: 3.75, exponent: 128)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(BigNumber.self, from: data)
        XCTAssertEqual(decoded, value)
    }

    func testNonFiniteInputCollapsesToZero() {
        XCTAssertTrue(BigNumber(.infinity).isZero)
        XCTAssertTrue(BigNumber(.nan).isZero)
    }
}
