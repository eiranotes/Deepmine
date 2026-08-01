import Foundation

/// One horizontal band of the shaft, as the player sees it.
public struct ShaftLayer: Identifiable, Equatable, Sendable {
    public enum Position: String, Equatable, Sendable {
        /// Already broken through. This is open shaft the player dug.
        case broken
        /// The face being worked right now. The only band that takes a strike.
        case current
        /// Unbroken rock below, waiting.
        case untouched
    }

    public let segment: RockSegment
    public let position: Position
    /// How well the lamp reaches this band, from 1 at the face to 0 at the edge of the
    /// dark. The renderer dims by this; nothing about the rock itself changes.
    public let lighting: Double
    /// True when this band is the first of its region, which is where the shaft earns a
    /// name plate instead of another identical stripe.
    public let isRegionEntrance: Bool

    public var id: Int { segment.index }
    public var depthMeters: Int {
        ProgressionEngine.depthMeters(forSegmentIndex: segment.index)
    }

    public init(
        segment: RockSegment,
        position: Position,
        lighting: Double,
        isRegionEntrance: Bool
    ) {
        self.segment = segment
        self.position = position
        self.lighting = lighting
        self.isRegionEntrance = isRegionEntrance
    }
}

/// Turns the player's position in the rock into the slice of shaft to draw.
///
/// This is game rule, not layout: how far the lamp reaches is bought with ore, so it
/// belongs with the other numbers rather than in a view.
public enum ShaftVision {
    /// Bands of rock still visible below the face. Grows with the lamp.
    public static func visibleLayersBelow(lampLevel: Int) -> Int {
        let steps = Double(Balance.levelsAboveBase(lampLevel))
        let reach = Balance.baseVisibleLayersBelow
            + steps * Balance.visibleLayersPerLampLevel
        return Int(min(Balance.maximumVisibleLayersBelow, max(1, reach)))
    }

    /// The shaft around the player, deepest last. Always contains exactly one `.current`
    /// band, so the renderer never has to decide which rock takes the tap.
    public static func layers(for state: PlayerState) -> [ShaftLayer] {
        let face = state.mineFace.segmentIndex
        let below = visibleLayersBelow(lampLevel: state.equipment.lamp)
        let top = max(0, face - Balance.visibleLayersAbove)

        return (top...(face + below)).map { index in
            let segment = RockGenerator.segment(at: index)
            let position: ShaftLayer.Position = index < face
                ? .broken
                : index == face ? .current : .untouched
            return ShaftLayer(
                segment: segment,
                position: position,
                lighting: lighting(at: index, face: face, below: below),
                isRegionEntrance: isRegionEntrance(segment)
            )
        }
    }

    /// Falls off below the face and stays full above it — the player is standing in the
    /// shaft they already opened, and it is lit.
    private static func lighting(at index: Int, face: Int, below: Int) -> Double {
        guard index > face else { return 1 }
        guard below > 0 else { return 0 }
        let distance = Double(index - face)
        return max(0, 1 - distance / Double(below + 1))
    }

    private static func isRegionEntrance(_ segment: RockSegment) -> Bool {
        guard segment.index > 0 else { return true }
        return RockGenerator.segment(at: segment.index - 1).region != segment.region
    }
}
