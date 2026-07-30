import DeepMineCore
import SwiftUI

/// The crew standing in the shaft. Reuses the single miner sprite at three sizes with
/// fixed offsets rather than adding new art, and fades the back rows so twelve figures
/// still read as depth instead of clutter.
///
/// Purely decorative: crew size comes from `MineCrew` and never feeds a reward.
struct MinerCrewScene: View {
    let crewSize: Int

    private struct Slot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    // Front row is largest and fully opaque; each row back steps down in size and
    // opacity so the group has a readable silhouette at 142pt tall.
    private static let slots: [Slot] = [
        Slot(x: 0, y: 0, size: 68, opacity: 1.0),
        Slot(x: 52, y: -6, size: 52, opacity: 0.92),
        Slot(x: 96, y: -3, size: 48, opacity: 0.86),
        Slot(x: 134, y: -10, size: 40, opacity: 0.78),
        Slot(x: 166, y: -5, size: 38, opacity: 0.72),
        Slot(x: 196, y: -13, size: 34, opacity: 0.66),
        Slot(x: 222, y: -7, size: 32, opacity: 0.6),
        Slot(x: 246, y: -15, size: 28, opacity: 0.54),
        Slot(x: 266, y: -9, size: 26, opacity: 0.48),
        Slot(x: 284, y: -17, size: 24, opacity: 0.43),
        Slot(x: 300, y: -11, size: 22, opacity: 0.38),
        Slot(x: 314, y: -19, size: 20, opacity: 0.33)
    ]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ForEach(Array(visibleSlots.enumerated()), id: \.offset) { index, slot in
                Image("MinerSprite")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: slot.size, height: slot.size)
                    .opacity(slot.opacity)
                    .offset(x: slot.x, y: slot.y)
                    .zIndex(Double(-index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(
            format: DeepMineStrings.text(.homeCrewLabel),
            visibleSlots.count
        ))
        .accessibilityIdentifier("mine-home-crew")
    }

    private var visibleSlots: [Slot] {
        let count = min(Self.slots.count, max(1, crewSize))
        return Array(Self.slots.prefix(count))
    }
}
