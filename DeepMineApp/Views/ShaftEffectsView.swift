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
            chip(burst, x: -54, y: -34, scale: 0.9)
            chip(burst, x: -20, y: -52, scale: 0.62)
            chip(burst, x: 28, y: -46, scale: 0.72)
            chip(burst, x: 58, y: -24, scale: 0.52)
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
    var progress: CGFloat = 0
    var opacity: Double = 1
}
