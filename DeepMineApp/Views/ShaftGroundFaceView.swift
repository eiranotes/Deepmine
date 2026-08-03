import DeepMineCore
import SwiftUI

/// The single, visible object the player is breaking at the head of the shaft.
/// Its material, crack reveal, tool stroke, and weak point all share one coordinate space.
struct ShaftWorkFaceView: View {
    let width: CGFloat
    let player: PlayerState
    let isStruck: Bool
    let strikeSignal: Int
    let strikeVariant: StrikeVariant
    let onStrike: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var impactOffset: CGFloat = 0
    @State private var impactCompression: CGFloat = 1
    @State private var impactFlash = false
    private var groundWidth: CGFloat { max(180, width - 18) }
    private let groundHeight: CGFloat = 134
    private let groundTop: CGFloat = 126
    /// The lip is drawn at its own aspect and then cropped from the top: the shoulders and
    /// the throat live in its lower half, and that is the part that has to meet the rock.
    private var lipHeight: CGFloat { 66 }
    /// D-055 overlaps the lip's underside with the cutting notch so the passage and the
    /// face read as one body rather than two stacked objects.
    private let lipOverlap: CGFloat = 3
    var body: some View {
        ZStack(alignment: .topLeading) {
            SuspendedMiningRigView(
                player: player,
                strikeSignal: strikeSignal,
                strikeVariant: strikeVariant
            )
            .position(x: width / 2, y: 66)

            groundButton
                .position(x: width / 2, y: groundTop + groundHeight / 2)

            frontierLip
                .position(x: width / 2, y: groundTop - lipHeight / 2 + lipOverlap)

            if let point = player.mineFace.segment.weakPoint {
                weakPoint(point)
            }
        }
        .frame(width: width, height: 262)
        // The face reacts when the pickaxe arrives, not when the input happens. Reduce
        // Motion shortens the whole timeline rather than removing the beat, so the hit is
        // still legible without the travel.
        .task(id: strikeSignal) {
            guard strikeSignal > 0 else { return }
            let timeline = StrikeTimeline.timeline(for: strikeVariant, reduceMotion: reduceMotion)
            do { try await Task.sleep(for: .seconds(timeline.contact)) }
            catch { return }
            impactOffset = reduceMotion
                ? 0
                : (strikeSignal.isMultiple(of: 2) ? -1 : 1) * recoil
            impactCompression = reduceMotion ? 1 : compression
            impactFlash = true
            do { try await Task.sleep(for: .milliseconds(140)) }
            catch { return }
            if reduceMotion {
                impactOffset = 0
                impactCompression = 1
                impactFlash = false
            } else {
                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.76)) {
                    impactOffset = 0
                    impactCompression = 1
                    impactFlash = false
                }
            }
        }
    }

    /// How much of the rock's width the contact disturbs. A 22pt spark under a 92pt actor
    /// made every hit look like a pinprick; the impact is a face-wide event (D-060).
    private var impactCoverage: CGFloat {
        switch strikeVariant {
        case .quick: 0.76
        case .heavy: 0.84
        case .critical: 0.92
        }
    }

    /// A heavier swing displaces the face further. Same damage, different read (D-058).
    private var recoil: CGFloat {
        switch strikeVariant {
        case .quick: 3
        case .heavy: 5
        case .critical: 7
        }
    }

    private var compression: CGFloat {
        switch strikeVariant {
        case .quick: 0.965
        case .heavy: 0.948
        case .critical: 0.93
        }
    }

    private var frontierLip: some View {
        GameArtView(
            entry: GameArtCatalog.shaftFrontierLip,
            fit: CGSize(width: groundWidth, height: groundWidth * 0.4)
        )
        .frame(width: groundWidth, height: lipHeight, alignment: .bottom)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var groundButton: some View {
        Button { onStrike(false) } label: {
            ShaftBreakableGroundView(
                player: player,
                impactFlash: impactFlash,
                impactCoverage: impactFlash ? impactCoverage : 0
            )
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
    /// Fraction of the rock's width the current contact covers. Zero between strikes.
    var impactCoverage: CGFloat = 0

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
                        region: player.mineFace.segment.region.rawValue,
                        depthMeters: Double(player.depthMeters)
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

                if impactCoverage > 0 {
                    impactField(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .clipped()
    }

    /// The compression band and its shock edges. Drawn inside the rock's own bounds so a
    /// wide hit reads as the face absorbing force rather than as an effect laid over it.
    private func impactField(width: CGFloat, height: CGFloat) -> some View {
        let band = width * impactCoverage
        return ZStack {
            Ellipse()
                .fill(DeepMinePalette.limestone.color.opacity(0.16))
                .frame(width: band, height: height * 0.26)
            Ellipse()
                .stroke(DeepMinePalette.limestone.color.opacity(0.5), lineWidth: 2)
                .frame(width: band * 0.82, height: height * 0.2)
            HStack(spacing: band * 0.52) {
                branchCrack
                branchCrack.scaleEffect(x: -1, y: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, height * 0.12)
        .allowsHitTesting(false)
    }

    private var branchCrack: some View {
        Rectangle()
            .fill(DeepMinePalette.coal.color.opacity(0.72))
            .frame(width: 2, height: 16)
            .rotationEffect(.degrees(18))
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
