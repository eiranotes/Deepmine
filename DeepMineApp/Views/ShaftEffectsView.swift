import DeepMineCore
import SwiftUI

struct ShaftEffectsView: View {
    let gains: [FloatingGain]
    let debris: [DebrisBurst]
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            ForEach(debris) { burst in
                debrisView(burst)
            }
            ForEach(gains) { gain in
                Text(gain.text)
                    .font(.headline.monospacedDigit().weight(.heavy))
                    .foregroundStyle(color(for: gain.kind))
                    .shadow(color: DeepMinePalette.coal.color, radius: 0, x: 2, y: 2)
                    .offset(x: gain.offsetX, y: 42 + gain.offsetY)
                    .opacity(gain.opacity)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func debrisView(_ burst: DebrisBurst) -> some View {
        ZStack {
            ForEach(0..<burst.density, id: \.self) { index in
                let angle = Double(index) / Double(max(1, burst.density)) * .pi
                let distance = CGFloat(42 + (index % 3) * 11)
                chip(
                    burst,
                    x: CGFloat(cos(angle)) * distance,
                    y: -CGFloat(sin(angle)) * distance
                        - CGFloat(index.isMultiple(of: 2) ? 8 : 0),
                    scale: 0.5 + CGFloat(index % 4) * 0.13
                )
            }
        }
        .opacity(burst.opacity)
    }

    private func chip(
        _ burst: DebrisBurst,
        x: CGFloat,
        y: CGFloat,
        scale: CGFloat
    ) -> some View {
        GameArtView(
            entry: GameArtCatalog.debris(isLarge: burst.isLarge),
            size: burst.isLarge ? 34 : 24
        )
        .scaleEffect(scale)
        .offset(
            x: x * (reduceMotion ? 0.28 : burst.progress),
            y: y * (reduceMotion ? 0.28 : burst.progress)
        )
    }

    private func color(for kind: FloatingGain.Kind) -> Color {
        switch kind {
        case .damage: DeepMinePalette.limestone.color
        case .critical, .ore: DeepMinePalette.brass.color
        }
    }
}

struct FloatingGain: Identifiable, Equatable {
    enum Kind: Equatable {
        case damage
        case critical
        case ore
    }

    let id = UUID()
    let text: String
    let kind: Kind
    var offsetX: Double
    var offsetY: Double = 0
    var opacity: Double = 1
}

struct DebrisBurst: Identifiable, Equatable {
    let id = UUID()
    let isLarge: Bool
    let density: Int
    var progress: CGFloat = 0
    var opacity: Double = 1
}

struct ShaftWorkingLightView: View {
    let scene: ShaftScene
    let width: CGFloat

    var body: some View {
        let headY = ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
        let reach = CGFloat(scene.visibleMetersBelow * Balance.shaftPointsPerMeter)
        let diameter = min(width * 1.35, max(120, reach * 2.1))
        RadialGradient(
            colors: [
                DeepMinePalette.brass.color.opacity(0.2),
                DeepMinePalette.brass.color.opacity(0.05),
                .clear
            ],
            center: .top,
            startRadius: 0,
            endRadius: diameter / 2
        )
        .frame(width: diameter, height: diameter / 1.55)
        .position(x: width / 2, y: headY + diameter / 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Visible automation. Cart power is not only a DPS label: the fleet traverses the
/// passage the player has already opened, and each branch changes the traffic itself.
struct ShaftCartTrafficView: View {
    let scene: ShaftScene
    let level: Int
    let modification: EquipmentModificationKind?
    let width: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var travelling = false

    private var count: Int {
        let tier = EquipmentEngine.visualTier(level: level)
        return min(4, max(1, tier) + (modification == .cartFleet ? 1 : 0))
    }

    private var duration: Double {
        let levels = max(0, level - Balance.minimumEquipmentLevel)
        let base = max(1.8, 5.2 - Double(levels) * 0.15)
        return modification == .cartFleet ? base * 0.78 : base
    }

    private var size: CGFloat { modification == .cartFreight ? 42 : 32 }
    private var startY: CGFloat { max(18, ShaftGeometry.y(for: scene.topDepthMeters, in: scene) + 18) }
    private var endY: CGFloat {
        max(startY + 10, ShaftGeometry.y(for: scene.headDepthMeters, in: scene) - 42)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<count, id: \.self) { index in
                let laneOffset = index.isMultiple(of: 2) ? -7.0 : 7.0
                let restingY = startY + (endY - startY) * CGFloat(index + 1) / CGFloat(count + 1)
                DeepMinePixelImage(
                    name: DeepMineArt.equipment(.cart, level: level),
                    size: size
                )
                .position(
                    x: width / 2 + laneOffset,
                    y: reduceMotion ? restingY : startY
                )
                .offset(y: reduceMotion || !travelling ? 0 : endY - startY)
                .animation(
                    reduceMotion
                        ? nil
                        : .linear(duration: duration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * duration / Double(max(1, count))),
                    value: travelling
                )
            }
        }
        .onAppear { travelling = !reduceMotion }
        .onChange(of: reduceMotion) { _, next in travelling = !next }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
