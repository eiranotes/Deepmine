import Foundation
/// Visual state captured when a segment is opened. Rendering old passage from these
/// records makes equipment purchases accumulate in the world instead of changing only
/// the next damage number.
public struct BoreRecord: Codable, Equatable, Identifiable, Sendable {
    public let segmentIndex: Int
    public let drillLevel: Int
    public let cartLevel: Int
    public let lampLevel: Int
    public let drillModification: EquipmentModificationKind?
    public var id: Int { segmentIndex }
    public init(
        segmentIndex: Int,
        drillLevel: Int,
        cartLevel: Int,
        lampLevel: Int,
        drillModification: EquipmentModificationKind? = nil
    ) {
        self.segmentIndex = max(0, segmentIndex)
        self.drillLevel = max(Balance.minimumEquipmentLevel, drillLevel)
        self.cartLevel = max(Balance.minimumEquipmentLevel, cartLevel)
        self.lampLevel = max(Balance.minimumEquipmentLevel, lampLevel)
        self.drillModification = drillModification?.equipment == .drill
            ? drillModification
            : nil
    }

    public var depthMeters: Int {
        ProgressionEngine.depthMeters(forSegmentIndex: segmentIndex)
    }

    public var boreWidthPoints: Double {
        EquipmentModificationEngine.boreWidth(
            drillLevel: drillLevel,
            modifications: EquipmentModifications(drill: drillModification)
        )
    }
}

/// The player's position in the rock: which segment they are on and how much of it is
/// left. This is the clicker's entire persistent position — everything else about the
/// current rock is regenerated from the index.
public struct MineFaceState: Codable, Equatable, Sendable {
    public private(set) var segmentIndex: Int
    public private(set) var remainingIntegrity: BigNumber
    public private(set) var impact: ImpactMeter
    /// Lifetime count. Segment index alone cannot serve: prestige resets the position but
    /// must not erase the history. No achievement watches this yet — the depth family
    /// covers the same ground and already has its badge art.
    public private(set) var lifetimeSegmentsBroken: Int
    public private(set) var lifetimeSeamsBroken: Int
    public private(set) var boreHistory: [BoreRecord]

    public init(
        segmentIndex: Int = 0,
        remainingIntegrity: BigNumber? = nil,
        impact: ImpactMeter = .empty,
        lifetimeSegmentsBroken: Int = 0,
        lifetimeSeamsBroken: Int = 0,
        boreHistory: [BoreRecord] = []
    ) {
        let index = max(0, segmentIndex)
        self.segmentIndex = index
        self.remainingIntegrity = remainingIntegrity
            ?? RockGenerator.segment(at: index).maximumIntegrity
        self.impact = impact
        self.lifetimeSegmentsBroken = max(0, lifetimeSegmentsBroken)
        self.lifetimeSeamsBroken = max(0, lifetimeSeamsBroken)
        self.boreHistory = Array(boreHistory.suffix(Balance.maximumBoreHistoryRecords))
    }

    private enum CodingKeys: String, CodingKey {
        case segmentIndex
        case remainingIntegrity
        case impact
        case lifetimeSegmentsBroken
        case lifetimeSeamsBroken
        case boreHistory
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            segmentIndex: try container.decode(Int.self, forKey: .segmentIndex),
            remainingIntegrity: try container.decode(BigNumber.self, forKey: .remainingIntegrity),
            impact: try container.decode(ImpactMeter.self, forKey: .impact),
            lifetimeSegmentsBroken: try container.decode(
                Int.self,
                forKey: .lifetimeSegmentsBroken
            ),
            lifetimeSeamsBroken: try container.decode(Int.self, forKey: .lifetimeSeamsBroken),
            boreHistory: try container.decodeIfPresent(
                [BoreRecord].self,
                forKey: .boreHistory
            ) ?? []
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(segmentIndex, forKey: .segmentIndex)
        try container.encode(remainingIntegrity, forKey: .remainingIntegrity)
        try container.encode(impact, forKey: .impact)
        try container.encode(lifetimeSegmentsBroken, forKey: .lifetimeSegmentsBroken)
        try container.encode(lifetimeSeamsBroken, forKey: .lifetimeSeamsBroken)
        try container.encode(boreHistory, forKey: .boreHistory)
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
    /// Damage that did not fit in this resolution. `MiningLoop` re-drives it; a caller that
    /// applies `MineFaceEngine` directly has to decide what to do with it.
    public let unspentDamage: BigNumber

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
        wasTruncated: Bool,
        unspentDamage: BigNumber = .zero
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
        self.unspentDamage = unspentDamage
    }
}

public enum MineFaceEngine {
    /// One manual strike.
    public static func strike<R: RandomNumberGenerator>(
        face: MineFaceState,
        power: StrikePower,
        hitWeakPoint: Bool,
        equipment: EquipmentLevels = EquipmentLevels(),
        modifications: EquipmentModifications = .empty,
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
            hitWeakPoint: outcome.hitWeakPoint,
            equipment: equipment,
            modifications: modifications,
            oreMultiplier: power.oreMultiplier
        )
    }

    /// Automation for an elapsed span. Also decays the impact meter, because time passing
    /// without taps is exactly what the meter measures.
    public static func advance(
        face: MineFaceState,
        power: StrikePower,
        seconds: TimeInterval,
        equipment: EquipmentLevels = EquipmentLevels(),
        modifications: EquipmentModifications = .empty,
        maximumSegments: Int = Balance.maximumSegmentsPerResolution
    ) -> MineFaceUpdate {
        let damage = StrikeEngine.automationDamage(power: power, seconds: seconds)
        return apply(
            damage: damage,
            to: face,
            impact: face.impact.decayed(by: seconds),
            wasCritical: false,
            hitWeakPoint: false,
            equipment: equipment,
            modifications: modifications,
            oreMultiplier: power.oreMultiplier,
            maximumSegments: maximumSegments
        )
    }

    /// Applies an explicit amount of damage. `MiningLoop` uses this to re-drive the
    /// remainder of a truncated resolution; nothing else should need it.
    public static func applyCarriedDamage(
        _ damage: BigNumber,
        to face: MineFaceState,
        equipment: EquipmentLevels = EquipmentLevels(),
        modifications: EquipmentModifications = .empty,
        oreMultiplier: Double = 1,
        maximumSegments: Int = Balance.maximumSegmentsPerResolution
    ) -> MineFaceUpdate {
        apply(
            damage: damage,
            to: face,
            impact: face.impact,
            wasCritical: false,
            hitWeakPoint: false,
            equipment: equipment,
            modifications: modifications,
            oreMultiplier: oreMultiplier,
            maximumSegments: maximumSegments
        )
    }

    private static func apply(
        damage: BigNumber,
        to face: MineFaceState,
        impact: ImpactMeter,
        wasCritical: Bool,
        hitWeakPoint: Bool,
        equipment: EquipmentLevels,
        modifications: EquipmentModifications,
        oreMultiplier: Double,
        maximumSegments: Int = Balance.maximumSegmentsPerResolution
    ) -> MineFaceUpdate {
        let resolution = RockEngine.resolve(
            damage: damage,
            segmentIndex: face.segmentIndex,
            remainingIntegrity: face.remainingIntegrity,
            maximumSegments: maximumSegments
        )
        let completedRecords = (0..<resolution.segmentsBroken).map { offset in
            BoreRecord(
                segmentIndex: face.segmentIndex + offset,
                drillLevel: equipment.drill,
                cartLevel: equipment.cart,
                lampLevel: equipment.lamp,
                drillModification: modifications.drill
            )
        }
        let updated = MineFaceState(
            segmentIndex: resolution.segmentIndex,
            remainingIntegrity: resolution.remainingIntegrity,
            impact: impact,
            lifetimeSegmentsBroken: face.lifetimeSegmentsBroken + resolution.segmentsBroken,
            lifetimeSeamsBroken: face.lifetimeSeamsBroken + resolution.seamsBroken,
            boreHistory: face.boreHistory + completedRecords
        )
        return MineFaceUpdate(
            face: updated,
            damage: damage,
            oreGained: resolution.oreGained * max(1, oreMultiplier),
            segmentsBroken: resolution.segmentsBroken,
            seamsBroken: resolution.seamsBroken,
            wasCritical: wasCritical,
            hitWeakPoint: hitWeakPoint,
            regionChanged: updated.region != face.region,
            wasTruncated: resolution.wasTruncated,
            unspentDamage: resolution.unspentDamage
        )
    }
}
