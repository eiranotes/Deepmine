import DeepMineCore
import SwiftUI

/// The decorations a player has unlocked, drawn into the shaft.
///
/// `MineDecoration` already existed in player state and was awarded by vault veins and
/// achievements, but nothing rendered it — the reward was invisible. Symbols are used
/// rather than new art so this stays within the four pigments.
struct MineDecorationScene: View {
    let decorations: Set<MineDecoration>

    private struct Placement {
        let decoration: MineDecoration
        let symbol: String
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double
    }

    // Pinned to the right side of the hero so the crew on the left stays legible.
    private static let placements: [Placement] = [
        Placement(decoration: .rail, symbol: "equal", size: 22, x: -6, y: 0, opacity: 0.5),
        Placement(decoration: .marker, symbol: "signpost.right.fill", size: 18, x: -34, y: -14, opacity: 0.7),
        Placement(decoration: .lamp, symbol: "lightbulb.max.fill", size: 16, x: -58, y: -34, opacity: 0.8),
        Placement(decoration: .cart, symbol: "tram.fill", size: 20, x: -80, y: -6, opacity: 0.62)
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ForEach(visible, id: \.decoration) { placement in
                Image(systemName: placement.symbol)
                    .font(.system(size: placement.size, weight: .semibold))
                    .foregroundStyle(DeepMinePalette.brass.color.opacity(placement.opacity))
                    .offset(x: placement.x, y: placement.y)
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
