import Darwin
import Foundation

protocol ProbeClockSource: Sendable {
    func wallNow() -> Date
    func continuousNanoseconds() -> UInt64
}

struct SystemProbeClockSource: ProbeClockSource {
    func wallNow() -> Date { Date() }

    func continuousNanoseconds() -> UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let ticks = mach_continuous_time()
        return UInt64(Double(ticks) * Double(timebase.numer) / Double(timebase.denom))
    }
}

struct ClockAnchor: Sendable {
    let wallClock: Date
    let continuousNanoseconds: UInt64
}

enum ClockIntegrityAssessment: String, Equatable, Sendable {
    case valid
    case tampered
    case rebooted
}

struct ClockObservation: Equatable, Sendable {
    let wallElapsed: TimeInterval
    let continuousElapsed: TimeInterval?
    let drift: TimeInterval?
    let assessment: ClockIntegrityAssessment
}

enum ClockProbe {
    static let defaultTamperThreshold: TimeInterval = 30

    static func start(source: some ProbeClockSource) -> ClockAnchor {
        ClockAnchor(
            wallClock: source.wallNow(),
            continuousNanoseconds: source.continuousNanoseconds()
        )
    }

    static func finish(
        anchor: ClockAnchor,
        source: some ProbeClockSource,
        tamperThreshold: TimeInterval = defaultTamperThreshold
    ) -> ClockObservation {
        let wallElapsed = source.wallNow().timeIntervalSince(anchor.wallClock)
        let endNanoseconds = source.continuousNanoseconds()

        guard endNanoseconds >= anchor.continuousNanoseconds else {
            return ClockObservation(
                wallElapsed: wallElapsed,
                continuousElapsed: nil,
                drift: nil,
                assessment: .rebooted
            )
        }

        let continuousElapsed = TimeInterval(endNanoseconds - anchor.continuousNanoseconds) / 1_000_000_000
        let drift = wallElapsed - continuousElapsed
        return ClockObservation(
            wallElapsed: wallElapsed,
            continuousElapsed: continuousElapsed,
            drift: drift,
            assessment: abs(drift) > tamperThreshold ? .tampered : .valid
        )
    }
}
