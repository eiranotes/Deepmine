import Foundation

public struct OfflineSettlement: Equatable, Sendable, Identifiable {
    public let elapsedSeconds: TimeInterval
    public let creditedSeconds: TimeInterval
    public let oreGained: BigNumber
    public let segmentsBroken: Int
    public let seamsBroken: Int
    public let regionChanged: Bool
    public let wasCapped: Bool
    public let wasRejected: Bool

    public var id: String {
        "\(elapsedSeconds)-\(segmentsBroken)-\(oreGained.scientificDescription)"
    }

    public var isEmpty: Bool {
        segmentsBroken == 0 && oreGained.isZero
    }

    public var isWorthReporting: Bool {
        !wasRejected
            && !isEmpty
            && elapsedSeconds >= Balance.minimumOfflineSecondsToReport
    }

    public static let none = OfflineSettlement(
        elapsedSeconds: 0, creditedSeconds: 0, oreGained: .zero,
        segmentsBroken: 0, seamsBroken: 0, regionChanged: false,
        wasCapped: false, wasRejected: false
    )

    public init(
        elapsedSeconds: TimeInterval,
        creditedSeconds: TimeInterval,
        oreGained: BigNumber,
        segmentsBroken: Int,
        seamsBroken: Int,
        regionChanged: Bool,
        wasCapped: Bool,
        wasRejected: Bool
    ) {
        self.elapsedSeconds = elapsedSeconds
        self.creditedSeconds = creditedSeconds
        self.oreGained = oreGained
        self.segmentsBroken = segmentsBroken
        self.seamsBroken = seamsBroken
        self.regionChanged = regionChanged
        self.wasCapped = wasCapped
        self.wasRejected = wasRejected
    }
}

extension MiningLoop {
    @discardableResult
    public static func settleOffline(
        since lastSettled: Date?,
        now: Date,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current,
        in state: inout PlayerState
    ) -> OfflineSettlement {
        defer { state.lastSettledAt = now }

        guard let lastSettled else { return .none }
        let elapsed = now.timeIntervalSince(lastSettled)
        guard elapsed.isFinite,
              elapsed > 0,
              elapsed <= Balance.maximumPlausibleOfflineSeconds else {
            return OfflineSettlement(
                elapsedSeconds: max(0, elapsed.isFinite ? elapsed : 0),
                creditedSeconds: 0, oreGained: .zero,
                segmentsBroken: 0, seamsBroken: 0, regionChanged: false,
                wasCapped: false, wasRejected: true
            )
        }

        let cap = Balance.maximumOfflineHours * 3_600
        let capped = min(elapsed, cap)
        let credited = capped * Balance.offlineEfficiency
        let update = advance(seconds: credited, in: &state)
        if update.segmentsBroken > 0 {
            try? MiningStreak.record(
                at: now,
                in: &state,
                calendar: calendar,
                timeZone: timeZone,
                incrementSessionCount: false
            )
        }

        return OfflineSettlement(
            elapsedSeconds: elapsed,
            creditedSeconds: credited,
            oreGained: update.oreGained,
            segmentsBroken: update.segmentsBroken,
            seamsBroken: update.seamsBroken,
            regionChanged: update.regionChanged,
            wasCapped: elapsed > cap,
            wasRejected: false
        )
    }
}
