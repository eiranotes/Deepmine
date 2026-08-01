import Foundation

/// One large geological body in the visible slice. Boundaries occur only where the
/// world changes region, never at the four-metre economy segment boundary.
public struct ShaftStratum: Identifiable, Equatable, Sendable {
    public let region: MineRegion
    public let startDepthMeters: Double
    public let endDepthMeters: Double
    public let isRegionEntrance: Bool

    public var id: String { "\(region.rawValue)-\(startDepthMeters)" }

    public init(
        region: MineRegion,
        startDepthMeters: Double,
        endDepthMeters: Double,
        isRegionEntrance: Bool
    ) {
        self.region = region
        self.startDepthMeters = startDepthMeters
        self.endDepthMeters = endDepthMeters
        self.isRegionEntrance = isRegionEntrance
    }
}

/// A continuous viewport around the drilling head.
public struct ShaftScene: Equatable, Sendable {
    public let topDepthMeters: Double
    public let bottomDepthMeters: Double
    public let faceDepthMeters: Double
    public let headDepthMeters: Double
    public let visibleMetersBelow: Double
    public let currentBoreWidthPoints: Double
    public let strata: [ShaftStratum]
    public let boreHistory: [BoreRecord]

    public var heightPoints: Double {
        (bottomDepthMeters - topDepthMeters) * Balance.shaftPointsPerMeter
    }

    public init(
        topDepthMeters: Double,
        bottomDepthMeters: Double,
        faceDepthMeters: Double,
        headDepthMeters: Double,
        visibleMetersBelow: Double,
        currentBoreWidthPoints: Double,
        strata: [ShaftStratum],
        boreHistory: [BoreRecord]
    ) {
        self.topDepthMeters = topDepthMeters
        self.bottomDepthMeters = bottomDepthMeters
        self.faceDepthMeters = faceDepthMeters
        self.headDepthMeters = headDepthMeters
        self.visibleMetersBelow = visibleMetersBelow
        self.currentBoreWidthPoints = currentBoreWidthPoints
        self.strata = strata
        self.boreHistory = boreHistory
    }

    public func y(forDepthMeters depth: Double) -> Double {
        (depth - topDepthMeters) * Balance.shaftPointsPerMeter
    }

    public func lighting(atDepthMeters depth: Double) -> Double {
        guard depth > headDepthMeters else { return 1 }
        guard visibleMetersBelow > 0 else { return 0 }
        return max(0, 1 - (depth - headDepthMeters) / visibleMetersBelow)
    }
}

public enum ShaftSceneEngine {
    public static func visibleMetersBelow(
        lampLevel: Int,
        modifications: EquipmentModifications = .empty
    ) -> Double {
        let steps = Double(Balance.levelsAboveBase(lampLevel))
        let reach = Balance.baseVisibleMetersBelow
            + steps * Balance.visibleMetersPerLampLevel
            + (modifications.lamp == .lampReach
                ? Balance.reachModificationVisibleMeters
                : 0)
        return min(Balance.maximumVisibleMetersBelow, max(1, reach))
    }

    public static func scene(for state: PlayerState) -> ShaftScene {
        let faceDepth = Double(state.depthMeters)
        let headDepth = faceDepth
            + state.mineFace.brokenFraction * Double(Balance.metersPerSegment)
        let below = visibleMetersBelow(
            lampLevel: state.equipment.lamp,
            modifications: state.equipmentModifications
        )
        // The viewport stays anchored to the start of the current four-metre economy
        // segment while the head travels through it. On breakthrough the geology moves
        // up by four metres and the head returns to its working line, producing one
        // continuous descent without turning the world back into bands.
        let top = max(0, faceDepth - Balance.shaftVisibleMetersAbove)
        let bottom = faceDepth + Double(Balance.metersPerSegment) + below
        return ShaftScene(
            topDepthMeters: top,
            bottomDepthMeters: bottom,
            faceDepthMeters: faceDepth,
            headDepthMeters: headDepth,
            visibleMetersBelow: below,
            currentBoreWidthPoints: EquipmentModificationEngine.boreWidth(
                drillLevel: state.equipment.drill,
                modifications: state.equipmentModifications
            ),
            strata: strata(from: top, through: bottom),
            boreHistory: state.mineFace.boreHistory.filter {
                let start = Double($0.depthMeters)
                let end = start + Double(Balance.metersPerSegment)
                return end >= top && start <= headDepth
            }
        )
    }

    private static func strata(from top: Double, through bottom: Double) -> [ShaftStratum] {
        let ranges: [(MineRegion, Double, Double)] = [
            (.entry, 0, Double(Balance.crystalRegionDepth)),
            (.crystal, Double(Balance.crystalRegionDepth), Double(Balance.ruinsRegionDepth)),
            (.ruins, Double(Balance.ruinsRegionDepth), Double(Balance.abyssRegionDepth)),
            (.abyss, Double(Balance.abyssRegionDepth), .greatestFiniteMagnitude)
        ]
        return ranges.compactMap { region, start, end in
            let visibleStart = max(top, start)
            let visibleEnd = min(bottom, end)
            guard visibleStart < visibleEnd else { return nil }
            return ShaftStratum(
                region: region,
                startDepthMeters: visibleStart,
                endDepthMeters: visibleEnd,
                isRegionEntrance: visibleStart == start && start >= top
            )
        }
    }
}
