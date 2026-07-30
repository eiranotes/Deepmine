import Foundation

public protocol ClockSource: Sendable {
    func wallNow() -> Date
    func continuousNanoseconds() -> UInt64
}

public struct ClockAnchor: Codable, Equatable, Sendable {
    public let wallClock: Date
    public let monotonicNanoseconds: UInt64

    public init(wallClock: Date, monotonicNanoseconds: UInt64) {
        self.wallClock = wallClock
        self.monotonicNanoseconds = monotonicNanoseconds
    }
}

public enum ClockIntegrityAssessment: String, Codable, Equatable, Sendable {
    case valid
    case rebooted
    case tampered
}

public struct ClockObservation: Codable, Equatable, Sendable {
    public let wallElapsed: TimeInterval
    public let monotonicElapsed: TimeInterval?
    public let drift: TimeInterval?
    public let acceptedElapsed: TimeInterval
    public let assessment: ClockIntegrityAssessment

    public init(
        wallElapsed: TimeInterval,
        monotonicElapsed: TimeInterval?,
        drift: TimeInterval?,
        acceptedElapsed: TimeInterval,
        assessment: ClockIntegrityAssessment
    ) {
        self.wallElapsed = wallElapsed
        self.monotonicElapsed = monotonicElapsed
        self.drift = drift
        self.acceptedElapsed = acceptedElapsed
        self.assessment = assessment
    }
}

public enum ClockIntegrityChecker {
    public static func start(source: some ClockSource) -> ClockAnchor {
        ClockAnchor(
            wallClock: source.wallNow(),
            monotonicNanoseconds: source.continuousNanoseconds()
        )
    }

    public static func finish(
        anchor: ClockAnchor,
        source: some ClockSource,
        tamperThreshold: TimeInterval = Balance.clockTamperThreshold
    ) -> ClockObservation {
        finish(
            anchor: anchor,
            endWallClock: source.wallNow(),
            endMonotonicNanoseconds: source.continuousNanoseconds(),
            tamperThreshold: tamperThreshold
        )
    }

    public static func finish(
        anchor: ClockAnchor,
        endWallClock: Date,
        endMonotonicNanoseconds: UInt64,
        tamperThreshold: TimeInterval = Balance.clockTamperThreshold
    ) -> ClockObservation {
        let wallElapsed = endWallClock.timeIntervalSince(anchor.wallClock)
        guard endMonotonicNanoseconds >= anchor.monotonicNanoseconds else {
            return ClockObservation(
                wallElapsed: wallElapsed,
                monotonicElapsed: nil,
                drift: nil,
                acceptedElapsed: wallElapsed,
                assessment: .rebooted
            )
        }

        let monotonicElapsed = TimeInterval(endMonotonicNanoseconds - anchor.monotonicNanoseconds)
            / Balance.nanosecondsPerSecond
        let drift = wallElapsed - monotonicElapsed
        let assessment: ClockIntegrityAssessment = abs(drift) > tamperThreshold ? .tampered : .valid
        return ClockObservation(
            wallElapsed: wallElapsed,
            monotonicElapsed: monotonicElapsed,
            drift: drift,
            acceptedElapsed: max(0, monotonicElapsed),
            assessment: assessment
        )
    }
}
