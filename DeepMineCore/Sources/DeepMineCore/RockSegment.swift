import Foundation

/// One breakable piece of rock. Segments are the unit of progress in the clicker loop:
/// strike until broken, collect ore, descend to the next one.
///
/// A segment is fully derived from its index, so it never has to be stored or synced —
/// the same index always produces the same rock on every device and every reinstall.
public struct RockSegment: Codable, Equatable, Sendable {
    public let index: Int
    public let region: MineRegion
    public let maximumIntegrity: BigNumber
    public let oreYield: BigNumber
    public let weakPoint: WeakPoint?
    /// Every nth segment is a seam: more integrity, disproportionately more ore. These
    /// are the pacing beats that keep descent from feeling flat.
    public let isSeam: Bool

    public init(
        index: Int,
        region: MineRegion,
        maximumIntegrity: BigNumber,
        oreYield: BigNumber,
        weakPoint: WeakPoint?,
        isSeam: Bool
    ) {
        self.index = index
        self.region = region
        self.maximumIntegrity = maximumIntegrity
        self.oreYield = oreYield
        self.weakPoint = weakPoint
        self.isSeam = isSeam
    }

    /// A struck-here-for-extra-damage target. Position is normalized so the renderer can
    /// place it without the engine knowing anything about pixels.
    public struct WeakPoint: Codable, Equatable, Sendable {
        public let unitX: Double
        public let unitY: Double
        public let multiplier: Double

        public init(unitX: Double, unitY: Double, multiplier: Double) {
            self.unitX = unitX
            self.unitY = unitY
            self.multiplier = multiplier
        }
    }

    /// Which of the four damage stages the art layer should show. Derived from remaining
    /// integrity so the visual and the number can never disagree.
    public func damageStage(remaining: BigNumber) -> Int {
        guard !maximumIntegrity.isZero else { return Balance.rockDamageStageCount }
        let ratio = (remaining / maximumIntegrity).doubleValue
        let clamped = min(1, max(0, ratio))
        let stage = Int(ceil(Double(Balance.rockDamageStageCount) * (1 - clamped)))
        return min(Balance.rockDamageStageCount, max(1, stage == 0 ? 1 : stage))
    }
}

public enum RockGenerator {
    /// Integrity compounds with depth while ore compounds slightly slower, so later
    /// segments take longer than they pay. That widening gap is what upgrades exist to
    /// close, and it is the whole reason a clicker keeps its pull.
    public static func segment(at index: Int) -> RockSegment {
        let safeIndex = max(0, index)
        let depth = ProgressionEngine.depthMeters(forSegmentIndex: safeIndex)
        let region = WorldProgression.region(forDepth: depth)
        let seam = safeIndex > 0 && safeIndex % Balance.seamSegmentInterval == 0

        var generator = SeededGenerator(seed: Balance.rockSeedSalt &+ UInt64(safeIndex))

        let integrityBase = BigNumber(Balance.baseSegmentIntegrity)
        let integrity = integrityBase
            * BigNumber(Balance.segmentIntegrityGrowthRate).raised(to: Double(safeIndex))
            * (seam ? Balance.seamIntegrityMultiplier : 1)

        let oreBase = BigNumber(Balance.baseSegmentOre)
        let ore = oreBase
            * BigNumber(Balance.segmentOreGrowthRate).raised(to: Double(safeIndex))
            * (seam ? Balance.seamOreMultiplier : 1)
            * regionOreMultiplier(region)

        let weakPoint = makeWeakPoint(using: &generator, region: region)

        return RockSegment(
            index: safeIndex,
            region: region,
            maximumIntegrity: integrity,
            oreYield: ore,
            weakPoint: weakPoint,
            isSeam: seam
        )
    }

    private static func makeWeakPoint(
        using generator: inout SeededGenerator,
        region: MineRegion
    ) -> RockSegment.WeakPoint? {
        let roll = Double.random(in: 0..<1, using: &generator)
        guard roll < Balance.weakPointChance else { return nil }
        // Inset from the edges so the target is never clipped by the rock's silhouette.
        let inset = Balance.weakPointEdgeInset
        return RockSegment.WeakPoint(
            unitX: Double.random(in: inset...(1 - inset), using: &generator),
            unitY: Double.random(in: inset...(1 - inset), using: &generator),
            multiplier: Balance.weakPointDamageMultiplier
                + Double(region.index) * Balance.weakPointRegionMultiplierStep
        )
    }

    private static func regionOreMultiplier(_ region: MineRegion) -> Double {
        switch region {
        case .entry: Balance.entryRegionOreMultiplier
        case .crystal: Balance.crystalRegionOreMultiplier
        case .ruins: Balance.ruinsRegionOreMultiplier
        case .abyss: Balance.abyssRegionOreMultiplier
        }
    }
}
