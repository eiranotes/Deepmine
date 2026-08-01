import DeepMineCore
import SwiftUI

/// The single, visible object the player is breaking at the head of the shaft.
/// Its material, crack reveal, tool stroke, and weak point all share one coordinate space.
struct ShaftWorkFaceView: View {
    let width: CGFloat
    let player: PlayerState
    let isStruck: Bool
    let strikeSignal: Int
    let onStrike: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var impactOffset: CGFloat = 0
    @State private var impactCompression: CGFloat = 1
    @State private var impactFlash = false

    private var groundWidth: CGFloat { max(180, width - 18) }
    private let groundHeight: CGFloat = 134
    private let groundTop: CGFloat = 52

    var body: some View {
        ZStack(alignment: .topLeading) {
            GameArtView(
                entry: GameArtCatalog.shaftGantry,
                fill: CGSize(width: min(width - 30, 280), height: 124)
            )
            .position(x: width / 2, y: 62)

            groundButton
                .position(x: width / 2, y: groundTop + groundHeight / 2)

            WorkingMinerView(
                isWorking: true,
                intensity: min(
                    1,
                    player.mineFace.impact.fraction
                        + (player.equipmentModifications.drill == .drillImpact ? 0.28 : 0)
                ),
                strikeSignal: strikeSignal,
                repeatsWhenIdle: false
            )
            .position(x: width / 2 - 30, y: 43)

            DeepMinePixelImage(
                name: DeepMineArt.equipment(.drill, level: player.equipment.drill),
                size: 39
            )
            .position(x: width / 2 + 46, y: 40)

            DeepMinePixelImage(
                name: DeepMineArt.equipment(.lamp, level: player.equipment.lamp),
                size: 25
            )
            .position(x: width - 35, y: 34)

            if let point = player.mineFace.segment.weakPoint {
                weakPoint(point)
            }
        }
        .frame(width: width, height: 188)
        .task(id: strikeSignal) {
            guard strikeSignal > 0 else { return }
            impactOffset = strikeSignal.isMultiple(of: 2) ? -3 : 3
            impactCompression = reduceMotion ? 1 : 0.965
            impactFlash = true
            try? await Task.sleep(for: .milliseconds(72))
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.76)) {
                impactOffset = 0
                impactCompression = 1
                impactFlash = false
            }
        }
    }

    private var groundButton: some View {
        Button { onStrike(false) } label: {
            ShaftBreakableGroundView(player: player, impactFlash: impactFlash)
                .frame(width: groundWidth, height: groundHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(ShaftGroundButtonStyle(reduceMotion: reduceMotion))
        .offset(x: impactOffset)
        .scaleEffect(x: 1, y: impactCompression, anchor: .top)
        .accessibilityIdentifier("rock-face")
        .accessibilityLabel(
            "\(DeepMineStrings.text(.gameDepth)) \(player.depthMeters)m, "
                + "\(DeepMineStrings.text(.mineIntegrity)) "
                + "\(Int((1 - player.mineFace.brokenFraction) * 100))%"
        )
    }

    private func weakPoint(_ point: RockSegment.WeakPoint) -> some View {
        Button { onStrike(true) } label: {
            GameArtView(entry: GameArtCatalog.weakPoint(isStruck: isStruck), size: 36)
                .shadow(
                    color: player.equipmentModifications.lamp == .lampFortune
                        ? DeepMinePalette.brass.color.opacity(0.9)
                        : .clear,
                    radius: player.equipmentModifications.lamp == .lampFortune ? 11 : 0
                )
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .position(
            x: (width - groundWidth) / 2 + groundWidth * point.unitX,
            y: groundTop + groundHeight * point.unitY
        )
        .accessibilityIdentifier("rock-weak-point")
        .accessibilityLabel(DeepMineStrings.text(.shaftWeakPoint))
    }
}

private struct ShaftBreakableGroundView: View {
    let player: PlayerState
    let impactFlash: Bool

    private var fractureIntensity: FractureIntensity {
        switch player.mineFace.damageStage {
        case ...1: .light
        case 2: .medium
        default: .heavy
        }
    }

    private var revealFraction: CGFloat {
        let progress = player.mineFace.brokenFraction
        guard progress > 0 else { return 0 }
        return CGFloat(min(1, 0.14 + progress * 0.86))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                GameArtView(
                    entry: GameArtCatalog.shaftRock(
                        region: player.mineFace.segment.region.rawValue
                    ),
                    fill: proxy.size
                )

                if player.mineFace.segment.isSeam {
                    GameArtView(
                        entry: GameArtCatalog.seamVein,
                        fill: CGSize(width: proxy.size.width, height: proxy.size.height)
                    )
                    .opacity(0.86)
                }

                GameArtView(
                    entry: GameArtCatalog.shaftFracture(intensity: fractureIntensity),
                    fit: CGSize(width: 72, height: 160)
                )
                .offset(y: -8)
                .mask(alignment: .top) {
                    Rectangle()
                        .frame(height: proxy.size.height * revealFraction)
                }
                .opacity(revealFraction == 0 ? 0 : 1)

                LinearGradient(
                    colors: [
                        .clear,
                        DeepMinePalette.coal.color.opacity(0.26)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Rectangle()
                    .fill(DeepMinePalette.limestone.color.opacity(impactFlash ? 0.9 : 0.42))
                    .frame(height: impactFlash ? 4 : 2)
                    .shadow(color: DeepMinePalette.coal.color.opacity(0.8), radius: 0, y: 3)
            }
        }
        .clipped()
    }
}

private struct ShaftGroundButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                x: configuration.isPressed && !reduceMotion ? 0.995 : 1,
                y: configuration.isPressed && !reduceMotion ? 0.955 : 1,
                anchor: .top
            )
            .offset(y: DeepMineMotion.pressOffset(
                isPressed: configuration.isPressed,
                reduceMotion: reduceMotion
            ))
            .brightness(configuration.isPressed ? 0.09 : 0)
            .overlay {
                Rectangle()
                    .stroke(
                        DeepMinePalette.brass.color.opacity(configuration.isPressed ? 0.82 : 0),
                        lineWidth: 2
                    )
            }
            .animation(
                DeepMineMotion.pressAnimation(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}
