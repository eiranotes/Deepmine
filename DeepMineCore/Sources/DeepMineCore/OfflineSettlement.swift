import Foundation

/// What the mine produced while the app was closed.
public struct OfflineSettlement: Equatable, Sendable, Identifiable {
    /// Real time since the last settlement, before the cap.
    public let elapsedSeconds: TimeInterval
    /// Time actually paid for, after the cap.
    public let creditedSeconds: TimeInterval
    public let oreGained: BigNumber
    public let segmentsBroken: Int
    public let seamsBroken: Int
    public let regionChanged: Bool
    /// The player was away longer than the cap allows. Worth saying out loud — a silent
    /// cap reads as a bug the first time someone returns after a weekend.
    public let wasCapped: Bool
    /// The elapsed time was not believable (clock moved backwards, or a timestamp from
    /// far in the future), so nothing was paid.
    public let wasRejected: Bool

    /// Distinct per settlement so a second return presents a fresh sheet rather than
    /// being suppressed as an unchanged item.
    public var id: String {
        "\(elapsedSeconds)-\(segmentsBroken)-\(oreGained.scientificDescription)"
    }

    public var isEmpty: Bool {
        segmentsBroken == 0 && oreGained.isZero
    }

    /// Whether returning deserves a sheet. A few seconds away is not a homecoming.
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
    /// Settles the time between two dates. Runs the same automation arithmetic as the
    /// on-screen tick, scaled by the offline efficiency, so a closed app and an open one
    /// never disagree about more than that single factor.
    @discardableResult
    public static func settleOffline(
        since lastSettled: Date?,
        now: Date,
        in state: inout PlayerState
    ) -> OfflineSettlement {
        defer { state.lastSettledAt = now }

        guard let lastSettled else { return .none }
        let elapsed = now.timeIntervalSince(lastSettled)

        // A backwards or absurd clock pays nothing. Cheating the mine by moving the
        // device clock must not be more profitable than playing it.
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
