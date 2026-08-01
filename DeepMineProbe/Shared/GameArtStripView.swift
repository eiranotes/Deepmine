import SwiftUI

/// Renders one frame of a horizontal sprite strip.
///
/// `GameArtView` draws a whole image, which is right for every slot that is one picture.
/// `MinerMiningStrip` is four frames of the same actor on one baseline, and the point of
/// binding them into a single asset (D-055) is that the body, both hands and the tool can
/// never drift onto separate timelines. Selecting a frame is therefore the only way this
/// asset is ever drawn.
struct GameArtStripView: View {
    let entry: GameArtEntry
    let frameCount: Int
    let frameIndex: Int
    let frameSize: CGSize

    private var safeIndex: Int {
        guard frameCount > 0 else { return 0 }
        return min(frameCount - 1, max(0, frameIndex))
    }

    var body: some View {
        Group {
            if GameArtAvailability.isInstalled(entry.name) {
                Image(entry.name)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .frame(
                        width: frameSize.width * CGFloat(max(1, frameCount)),
                        height: frameSize.height
                    )
                    .offset(x: -frameSize.width * CGFloat(safeIndex))
                    .frame(width: frameSize.width, height: frameSize.height, alignment: .leading)
            } else {
                GameArtPlaceholderView(placeholder: entry.placeholder)
                    .frame(width: frameSize.width, height: frameSize.height)
            }
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .clipped()
        .accessibilityHidden(true)
    }
}
