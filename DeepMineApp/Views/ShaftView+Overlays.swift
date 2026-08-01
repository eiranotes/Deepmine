import DeepMineCore
import SwiftUI

/// Overlays drawn on top of the shaft column: the surface canopy, the depth ruler and the
/// region plates. Split from `ShaftView` only to keep both files under the 300-line limit.
extension ShaftView {
    var surfaceCanopy: some View {
        GeometryReader { proxy in
            GameArtView(entry: GameArtCatalog.shaftSurface, fill: proxy.size)
        }
        .frame(height: 54)
        .opacity(0.88)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    func depthRuler(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(ShaftGeometry.depthMarks(in: scene), id: \.self) { depth in
                HStack(spacing: 3) {
                    Rectangle()
                        .fill(DeepMinePalette.limestone.color.opacity(0.45))
                        .frame(width: 8, height: 1)
                    Text("\(depth)m")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(DeepMinePalette.coal.color.opacity(0.68), in: Capsule())
                .position(
                    x: 30,
                    y: ShaftGeometry.y(for: Double(depth), in: scene)
                )
            }
            Text("\(Int(scene.headDepthMeters.rounded()))m")
                .font(.caption2.monospacedDigit().weight(.black))
                .foregroundStyle(DeepMinePalette.coal.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(DeepMinePalette.brass.color, in: Capsule())
                .position(
                    x: 31,
                    y: ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
                )
        }
        .frame(width: width)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    func regionPlates(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(scene.strata.filter(\.isRegionEntrance)) { stratum in
                if stratum.startDepthMeters > 0 {
                    Text(DeepMineStrings.text(DeepMineProgressLabels.regionKey(stratum.region)))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DeepMinePalette.coal.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(DeepMinePalette.brass.color, in: Capsule())
                        .position(
                            x: width - 46,
                            y: ShaftGeometry.y(for: stratum.startDepthMeters, in: scene) + 12
                        )
                        .accessibilityIdentifier("shaft-region-\(stratum.region.rawValue)")
                }
            }
        }
        .frame(width: width)
        .allowsHitTesting(false)
    }
}
