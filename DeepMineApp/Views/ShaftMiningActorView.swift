import DeepMineCore
import SwiftUI

/// The miner, both hands and the pickaxe as one actor on one timeline (D-055).
///
/// Before this, the body looped on its own period while the tool swung on another, so the
/// pickaxe could land while the miner was mid-recovery and the force never read as
/// transferred. A single four-frame strip makes that class of mismatch unrepresentable:
/// there is one frame index, and every limb is in it.
struct ShaftMiningActorView: View {
    let strikeSignal: Int
    var variant: StrikeVariant = .quick
    var height: CGFloat = 96

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frameIndex = 0
    @State private var lunge: CGFloat = 0

    private var timeline: StrikeTimeline {
        StrikeTimeline.timeline(for: variant, reduceMotion: reduceMotion)
    }

    var body: some View {
        GameArtStripView(
            entry: GameArtCatalog.minerMiningStrip,
            frameCount: GameArtCatalog.minerMiningFrameCount,
            frameIndex: frameIndex,
            frameSize: CGSize(width: height, height: height)
        )
        .offset(y: lunge)
        // The actor is what a strike looks like, never what receives it. At 92pt it covers
        // the top of the rock button, and a tap that lands on the miner is a tap the player
        // aimed at the rock and did not get.
        .allowsHitTesting(false)
        .task(id: strikeSignal) {
            guard strikeSignal > 0 else { return }
            await playSwing()
        }
    }

    /// Walks the strip rather than animating between poses: pixel frames are drawn, not
    /// interpolated, and the contact frame has to be on screen at the contact instant.
    private func playSwing() async {
        let timeline = timeline
        let steps: [(TimeInterval, Int)] = [
            (0, 1),
            (timeline.contact * 0.55, 2),
            (timeline.contact + min(timeline.duration - timeline.contact, timeline.contact * 0.42), 3),
            (timeline.duration, 0),
        ]

        var previous: TimeInterval = 0
        for (offset, index) in steps {
            let delay = offset - previous
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            previous = offset
            frameIndex = index
            // Travel is the part Reduce Motion drops; the pose change and the reward stay.
            lunge = reduceMotion ? 0 : (index == 2 ? 5 : index == 3 ? -2 : 0)
        }
        frameIndex = 0
        lunge = 0
    }
}
