import DeepMineCore
import SwiftUI

/// Where each band sits in the column. Kept apart from the view so the ruler and the rock
/// cannot drift out of alignment.
enum ShaftGeometry {
    static let brokenHeight: CGFloat = 30
    static let faceHeight: CGFloat = 128
    static let untouchedHeight: CGFloat = 44

    /// Distance from the top of the column to the face. Constant, so the rock the player
    /// is hitting never moves under their thumb.
    static var faceTop: CGFloat { brokenHeight * CGFloat(Balance.visibleLayersAbove) }

    static func height(of position: ShaftLayer.Position) -> CGFloat {
        switch position {
        case .broken: brokenHeight
        case .current: faceHeight
        case .untouched: untouchedHeight
        }
    }

    static func offset(of index: Int, face: Int) -> CGFloat {
        let delta = index - face
        if delta < 0 {
            return brokenHeight * CGFloat(Balance.visibleLayersAbove + delta)
        }
        if delta == 0 { return faceTop }
        return faceTop + faceHeight + untouchedHeight * CGFloat(delta - 1)
    }

    static func columnHeight(below: Int) -> CGFloat {
        faceTop + faceHeight + untouchedHeight * CGFloat(max(1, below))
    }
}
