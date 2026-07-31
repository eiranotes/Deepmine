import Foundation
import XCTest
@testable import DeepMine

final class ClockProbeTests: XCTestCase {
    func testNormalDriftIsValid() {
        let anchor = ClockAnchor(
            wallClock: Date(timeIntervalSince1970: 1_000),
            continuousNanoseconds: 10_000_000_000
        )
        let source = FixedProbeClock(
            wall: Date(timeIntervalSince1970: 1_060),
            nanoseconds: 64_000_000_000
        )

        let result = ClockProbe.finish(anchor: anchor, source: source)

        XCTAssertEqual(result.assessment, .valid)
        XCTAssertEqual(try XCTUnwrap(result.drift), 6, accuracy: 0.000_1)
    }

    func testExactlyThirtySecondsRemainsValid() {
        let anchor = ClockAnchor(wallClock: .distantPast, continuousNanoseconds: 1_000_000_000)
        let source = FixedProbeClock(
            wall: anchor.wallClock.addingTimeInterval(60),
            nanoseconds: 31_000_000_000
        )

        XCTAssertEqual(ClockProbe.finish(anchor: anchor, source: source).assessment, .valid)
    }

    func testMoreThanThirtySecondsIsTampered() {
        let anchor = ClockAnchor(wallClock: .distantPast, continuousNanoseconds: 1_000_000_000)
        let source = FixedProbeClock(
            wall: anchor.wallClock.addingTimeInterval(60),
            nanoseconds: 30_000_000_000
        )

        XCTAssertEqual(ClockProbe.finish(anchor: anchor, source: source).assessment, .tampered)
    }

    func testCounterRollbackIsRebooted() {
        let anchor = ClockAnchor(wallClock: .distantPast, continuousNanoseconds: 20)
        let source = FixedProbeClock(
            wall: anchor.wallClock.addingTimeInterval(60),
            nanoseconds: 10
        )

        let result = ClockProbe.finish(anchor: anchor, source: source)

        XCTAssertEqual(result.assessment, .rebooted)
        XCTAssertNil(result.continuousElapsed)
        XCTAssertNil(result.drift)
    }
}

private struct FixedProbeClock: ProbeClockSource {
    let wall: Date
    let nanoseconds: UInt64

    func wallNow() -> Date { wall }
    func continuousNanoseconds() -> UInt64 { nanoseconds }
}
