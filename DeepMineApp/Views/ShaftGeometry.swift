import DeepMineCore
import SwiftUI

/// Depth is the only layout coordinate in the mine. Every visible object converts from
/// metres through this helper, so the ruler, geology, old passage and drilling head
/// cannot drift apart.
enum ShaftGeometry {
    static func y(for depth: Double, in scene: ShaftScene) -> CGFloat {
        surfaceInset(for: scene) + CGFloat(scene.y(forDepthMeters: depth))
    }

    static func height(from start: Double, to end: Double) -> CGFloat {
        CGFloat(max(0, end - start) * Balance.shaftPointsPerMeter)
    }

    static func columnHeight(for scene: ShaftScene) -> CGFloat {
        surfaceInset(for: scene) + CGFloat(scene.heightPoints)
    }

    static func depthMarks(in scene: ShaftScene) -> [Int] {
        let first = max(0, Int(ceil(scene.topDepthMeters / 20)) * 20)
        let last = Int(floor(scene.bottomDepthMeters / 20)) * 20
        guard first <= last else { return [] }
        return Array(stride(from: first, through: last, by: 20))
    }

    /// Before 24m there is not enough mined history to occupy the upper viewport. Keep
    /// that missing distance as open surface shaft instead of pinning the work head to
    /// y=0, where the miner and fracture would be clipped.
    private static func surfaceInset(for scene: ShaftScene) -> CGFloat {
        CGFloat(max(0, Balance.shaftVisibleMetersAbove - scene.faceDepthMeters)
            * Balance.shaftPointsPerMeter)
    }
}
