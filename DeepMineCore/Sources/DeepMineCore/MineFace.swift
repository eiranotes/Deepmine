import Foundation

/// The player's position in the rock: which segment they are on and how much of it is
/// left. This is the clicker's entire persistent position — everything else about the
/// current rock is regenerated from the index.
public struct MineFaceState: Codable, Equatable, Sendable {
    public private(set) var segmentIndex: Int
    public private(set) var remainingIntegrity: BigNumber
    public private(set) var impact: ImpactMeter
    /// Lifetime count, used by achievements and the growth ledger. Segment index alone
    /// cannot serve: prestige may reset position but must not erase history.
    public private(set) var lifetimeSegmentsBroken: Int
    public private(set) var lifetimeSeamsBroken: Int

    public init(
        segmentIndex: Int = 0,
        remainingIntegrity: BigNumber? = nil,
        impact: ImpactMeter = .empty,
        lifetimeSegmentsBroken: Int = 0,
        lifetimeSeamsBroken: Int = 0
    ) {
        let index = max(0, segmentIndex)
        self.segmentIndex = index
        self.remainingIntegrity = remainingIntegrity
            ?? RockGenerator.segment(at: index).maximumIntegrity
        self.impact = impact
        self.lifetimeSegmentsBroken = max(0, lifetimeSegmentsBroken)
        self.lifetimeSeamsBroken = max(0, lifetimeSeamsBroken)
    }

    public var segment: RockSegment {
        RockGenerator.segment(at: segmentIndex)
    }

    public var damageStage: Int {
        segment.damageStage(remaining: remainingIntegrity)
    }

    /// How far through the current rock the player is, for the progress bar.
    public var brokenFraction: Double {
        let maximum = segment.maximumIntegrity
        guard !maximum.isZero else { return 1 }
        let ratio = (remainingIntegrity / maximum).doubleValue
        return min(1, max(0, 1 - ratio))
    }

    public var depthMeters: Int {
        ProgressionEngine.depthMeters(forSegmentIndex: segmentIndex)
    }

    public var region: MineRegion {
        segment.region
    }
}

/// What one strike or one automation tick did, in the form the UI needs to animate it.
public struct MineFaceUpdate: Equatable, Sendable {
    public let face: MineFaceState
    public let damage: BigNumber
    public let oreGained: BigNumber
    public let segmentsBroken: Int
    public let seamsBroken: Int
    public let wasCritical: Bool
    public let hitWeakPoint: Bool
    public let regionChanged: Bool
    public let wasTruncated: Bool

    public var brokeSomething: Bool { segmentsBroken > 0 }

    public init(
        face: MineFaceState,
        damage: BigNumber,
        oreGained: BigNumber,
        segmentsBroken: Int,
        seamsBroken: Int,
        wasCritical: Bool,
        hitWeakPoint: Bool,
        regionChanged: Bool,
        wasTruncated: Bool
    ) {
        self.face = face
        self.damage = damage
        self.oreGained = oreGained
        self.segmentsBroken = segmentsBroken
        self.seamsBroken = seamsBroken
        self.wasCritical = wasCritical
        self.hitWeakPoint = hitWeakPoint
        self.regionChanged = regionChanged
        self.wasTruncated = wasTruncated
    }
}

public enum MineFaceEngine {
    /// One manual strike.
    public static func strike<R: RandomNumberGenerator>(
        face: MineFaceState,
        power: StrikePower,
        hitWeakPoint: Bool,
        using generator: inout R
    ) -> MineFaceUpdate {
        let weakPointMultiplier = face.segment.weakPoint?.multiplier ?? 1
        let outcome = StrikeEngine.tap(
            power: power,
            impact: face.impact,
            hitWeakPoint: hitWeakPoint && face.segment.weakPoint != nil,
            weakPointMultiplier: weakPointMultiplier,
            using: &generator
        )
        return apply(
            damage: outcome.damage,
            to: face,
            impact: outcome.impact,
            wasCritical: outcome.wasCritical,
            hitWeakPoint: outcome.hitWeakPoint
        )
    }

    /// Automation for an elapsed span. Also decays the impact meter, because time passing
    /// without taps is exactly what the meter measures.
    public static func advance(
        face: MineFaceState,
        power: StrikePower,
        seconds: TimeInterval,
        maximumSegments: Int = Balance.maximumSegmentsPerResolution
    ) -> MineFaceUpdate {
        let damage = StrikeEngine.automationDamage(power: power, seconds: seconds)
        return apply(
            damage: damage,
            to: face,
            impact: face.impact.decayed(by: seconds),
            wasCritical: false,
            hitWeakPoint: false,
            maximumSegments: maximumSegments
        )
    }

    private static func apply(
        damage: BigNumber,
        to face: MineFaceState,
        impact: ImpactMeter,
        wasCritical: Bool,
        hitWeakPoint: Bool,
        maximumSegments: Int = Balance.maximumSegmentsPerResolution
    ) -> MineFaceUpdate {
        let resolution = RockEngine.resolve(
            damage: damage,
            segmentIndex: face.segmentIndex,
            remainingIntegrity: face.remainingIntegrity,
            maximumSegments: maximumSegments
        )
        let updated = MineFaceState(
            segmentIndex: resolution.segmentIndex,
            remainingIntegrity: resolution.remainingIntegrity,
            impact: impact,
            lifetimeSegmentsBroken: face.lifetimeSegmentsBroken + resolution.segmentsBroken,
            lifetimeSeamsBroken: face.lifetimeSeamsBroken + resolution.seamsBroken
        )
        return MineFaceUpdate(
            face: updated,
            damage: damage,
            oreGained: resolution.oreGained,
            segmentsBroken: resolution.segmentsBroken,
            seamsBroken: resolution.seamsBroken,
            wasCritical: wasCritical,
            hitWeakPoint: hitWeakPoint,
            regionChanged: updated.region != face.region,
            wasTruncated: resolution.wasTruncated
        )
    }
}
