import Foundation

extension PlayerState {
    /// Derived from the rock face. Focus changes how quickly the face moves; it never
    /// manufactures depth by itself.
    public var depthMeters: Int {
        depth(forSegmentIndex: mineFace.segmentIndex)
    }

    /// The deepest point ever reached, which prestige does not undo. Equipment ceilings,
    /// region unlocks and depth achievements all read the record (D-046).
    public var recordDepthMeters: Int {
        max(depthMeters, depth(forSegmentIndex: deepestSegmentIndex))
    }

    public var unlockedEquipmentLevel: Int {
        Balance.maximumEquipmentLevel(forDepth: recordDepthMeters)
    }

    /// Abyss veins skip intact rock rather than pretending the current rock lives at a
    /// different depth. The small remainder exists only for compatibility with older
    /// saves whose bonus was not a multiple of the four-metre segment size.
    mutating func skipUnbrokenDepth(meters: Int) {
        guard meters > 0 else { return }
        bonusDepthMeters = saturatingAdd(max(0, bonusDepthMeters), meters)
        normalizeDepthOffset()
    }

    /// Migrates the former virtual-depth field into the real mine position. This runs
    /// after both normal initialization and decoding, so old saves and new rewards share
    /// one source of truth without a separate persistence migration.
    mutating func normalizeDepthOffset() {
        let normalizedBonus = max(0, bonusDepthMeters)
        let segmentDelta = normalizedBonus / Balance.metersPerSegment
        bonusDepthMeters = normalizedBonus % Balance.metersPerSegment
        guard segmentDelta > 0 else { return }

        mineFace = shifted(mineFace, by: segmentDelta)
        deepestSegmentIndex = saturatingAdd(max(0, deepestSegmentIndex), segmentDelta)
        deepestSegmentIndex = max(deepestSegmentIndex, mineFace.segmentIndex)
    }

    private func depth(forSegmentIndex index: Int) -> Int {
        let base = ProgressionEngine.depthMeters(forSegmentIndex: index)
        return saturatingAdd(base, max(0, bonusDepthMeters))
    }

    private func shifted(_ face: MineFaceState, by segments: Int) -> MineFaceState {
        MineFaceState(
            segmentIndex: saturatingAdd(face.segmentIndex, segments),
            impact: face.impact,
            lifetimeSegmentsBroken: face.lifetimeSegmentsBroken,
            lifetimeSeamsBroken: face.lifetimeSeamsBroken
        )
    }

    private func saturatingAdd(_ value: Int, _ addition: Int) -> Int {
        guard value >= 0, addition >= 0 else { return max(0, addition) }
        return value > Int.max - addition ? Int.max : value + addition
    }
}
