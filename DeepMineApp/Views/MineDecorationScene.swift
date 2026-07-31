import DeepMineCore
import SwiftUI

/// The decorations a player has unlocked, drawn into the shaft.
///
/// `MineDecoration` is awarded by vault veins and achievements. Each unlocked reward
/// is rendered from the shared four-pigment sprite catalog.
struct MineDecorationScene: View {
    let decorations: Set<MineDecoration>

    private struct Placement {
        let decoration: MineDecoration
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double
    }

    // Pinned to the right side of the hero so the crew on the left stays legible.
    private static let placements: [Placement] = [
        Placement(decoration: .rail, size: 34, x: -4, y: 0, opacity: 0.72),
        Placement(decoration: .marker, size: 28, x: -38, y: -16, opacity: 0.84),
        Placement(decoration: .lamp, size: 26, x: -64, y: -38, opacity: 0.92),
        Placement(decoration: .cart, size: 32, x: -92, y: -4, opacity: 0.78)
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ForEach(visible, id: \.decoration) { placement in
                DeepMinePixelImage(
                    name: DeepMineArt.decoration(placement.decoration),
                    size: placement.size
                )
                    .opacity(placement.opacity)
                    .offset(x: placement.x, y: placement.y)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottomTrailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(
            format: DeepMineStrings.text(.homeDecorationLabel),
            visible.count
        ))
        .accessibilityHidden(visible.isEmpty)
        .accessibilityIdentifier("mine-home-decorations")
    }

    private var visible: [Placement] {
        Self.placements.filter { decorations.contains($0.decoration) }
    }
}
