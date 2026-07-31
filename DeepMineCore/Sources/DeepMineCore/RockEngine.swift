import Foundation

/// The result of applying damage to the rock face. One resolution can span many segments,
/// because automation running while the app was closed arrives as a single large amount.
public struct StrikeResolution: Equatable, Sendable {
    public let segmentIndex: Int
    public let remainingIntegrity: BigNumber
    public let segmentsBroken: Int
    public let oreGained: BigNumber
    public let seamsBroken: Int
    /// True when the damage exceeded what one resolution is allowed to walk. The unspent
    /// remainder is dropped, and the caller is expected to surface or re-drive it rather
    /// than assume the whole amount landed.
    public let wasTruncated: Bool

    public init(
        segmentIndex: Int,
        remainingIntegrity: BigNumber,
        segmentsBroken: Int,
        oreGained: BigNumber,
        seamsBroken: Int,
        wasTruncated: Bool
    ) {
        self.segmentIndex = segmentIndex
        self.remainingIntegrity = remainingIntegrity
        self.segmentsBroken = segmentsBroken
        self.oreGained = oreGained
        self.seamsBroken = seamsBroken
        self.wasTruncated = wasTruncated
    }
}

public enum RockEngine {
    /// Walks damage across consecutive segments, carrying the overflow from each break
    /// into the next rock. Carrying matters: without it a huge offline haul would break
    /// exactly one segment and quietly discard the rest.
    public static func resolve(
        damage: BigNumber,
        segmentIndex: Int,
        remainingIntegrity: BigNumber,
        maximumSegments: Int = Balance.maximumSegmentsPerResolution
    ) -> StrikeResolution {
        var index = max(0, segmentIndex)
        var remaining = remainingIntegrity
        var unspent = damage
        var broken = 0
        var seams = 0
        var ore = BigNumber.zero

        guard !damage.isZero, !damage.isNegative else {
            return StrikeResolution(
                segmentIndex: index,
                remainingIntegrity: remaining,
                segmentsBroken: 0,
                oreGained: .zero,
                seamsBroken: 0,
                wasTruncated: false
            )
        }

        while unspent > .zero {
            if unspent < remaining {
                remaining = remaining - unspent
                unspent = .zero
                break
            }
            let segment = RockGenerator.segment(at: index)
            ore += segment.oreYield
            if segment.isSeam { seams += 1 }
            unspent = unspent - remaining
            broken += 1
            index += 1
            remaining = RockGenerator.segment(at: index).maximumIntegrity

            if broken >= maximumSegments {
                return StrikeResolution(
                    segmentIndex: index,
                    remainingIntegrity: remaining,
                    segmentsBroken: broken,
                    oreGained: ore,
                    seamsBroken: seams,
                    wasTruncated: true
                )
            }
        }

        return StrikeResolution(
            segmentIndex: index,
            remainingIntegrity: remaining,
            segmentsBroken: broken,
            oreGained: ore,
            seamsBroken: seams,
            wasTruncated: false
        )
    }
}
