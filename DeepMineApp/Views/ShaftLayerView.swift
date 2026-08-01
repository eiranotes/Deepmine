import DeepMineCore
import SwiftUI

/// One horizontal band of the shaft.
///
/// Each region owns one wide rock-wall texture. Damage remains procedural and overlays
/// that texture, so the face can change on every strike without returning to a row of
/// repeated square boulders.
struct ShaftLayerView: View {
    let layer: ShaftLayer
    let isStruck: Bool
    let brokenFraction: Double
    let onStrike: (Bool) -> Void

    var body: some View {
        ZStack {
            switch layer.position {
            case .broken: openShaft
            case .current: face
            case .untouched: unbrokenRock
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .overlay(alignment: .top) { shaftWalls }
    }

    // MARK: Bands

    /// Rock the player already broke: a dark opening with the cut walls left behind.
    private var openShaft: some View {
        ZStack {
            DeepMinePalette.coal.color
            // Hewn rock, not empty black. The band has to read as a place the player cut
            // through rather than as a gap in the layout.
            LinearGradient(
                colors: [
                    DeepMinePalette.shale.color,
                    DeepMinePalette.shale.color.opacity(0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Rectangle()
                .fill(DeepMinePalette.limestone.color.opacity(0.07))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .bottom)
            if layer.segment.isSeam {
                // A worked-out seam is worth remembering; it is where the ore was.
                GameArtView(entry: GameArtCatalog.debris(isLarge: true), size: 22)
                    .opacity(0.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 24)
            }
        }
        .accessibilityHidden(true)
    }

    /// The band being worked. The only one that takes a tap.
    private var face: some View {
        ZStack {
            rockTexture
            if layer.segment.isSeam { seamVein }
            // Damage reads as the rock giving way from the top down, which is the
            // direction the player is going.
            GeometryReader { proxy in
                DeepMinePalette.coal.color
                    .frame(height: proxy.size.height * brokenFraction)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(DeepMinePalette.brass.color.opacity(0.7))
                            .frame(height: 1.5)
                    }
            }
            .allowsHitTesting(false)
            if damageStage > 1 {
                GameArtView(entry: GameArtCatalog.fracture(intensity: fractureIntensity), size: height)
                    .opacity(0.85)
                    .allowsHitTesting(false)
            }
            if let point = layer.segment.weakPoint {
                weakPoint(point)
            }
            gantry
        }
        // The face is the one band that takes a tap, so it says so with an edge rather
        // than relying on the player noticing it is taller than its neighbours.
        .overlay {
            Rectangle()
                .stroke(DeepMinePalette.brass.color.opacity(0.85), lineWidth: 2)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { onStrike(false) }
        .accessibilityIdentifier("rock-face")
        .accessibilityLabel(Text("\(DeepMineStrings.text(.gameDepth)) \(layer.depthMeters)m"))
        .accessibilityAddTraits(.isButton)
    }

    /// Rock below the face, dimmed by how far the lamp reaches. The falloff is curved
    /// rather than linear: on already-dark art a straight ramp barely reads, and the
    /// point of the band is that the shaft disappears into the dark.
    private var unbrokenRock: some View {
        ZStack {
            rockTexture
            if layer.segment.isSeam { seamVein }
            DeepMinePalette.coal.color.opacity(1 - pow(max(0, layer.lighting), 1.8))
        }
        .accessibilityHidden(true)
    }

    // MARK: Parts

    private var rockTexture: some View {
        GeometryReader { proxy in
            GameArtView(
                entry: GameArtCatalog.shaftRock(region: layer.segment.region.rawValue),
                fill: proxy.size
            )
        }
    }

    private var gantry: some View {
        GeometryReader { proxy in
            GameArtView(
                entry: GameArtCatalog.shaftGantry,
                size: height,
                fill: proxy.size
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var seamVein: some View {
        GeometryReader { proxy in
            GameArtView(
                entry: GameArtCatalog.seamVein,
                size: height,
                fill: proxy.size
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func weakPoint(_ point: RockSegment.WeakPoint) -> some View {
        GeometryReader { proxy in
            GameArtView(entry: GameArtCatalog.weakPoint(isStruck: isStruck), size: 36)
                .frame(width: 48, height: 48)
                .position(
                    x: proxy.size.width * point.unitX,
                    y: proxy.size.height * point.unitY
                )
                .contentShape(Rectangle())
                .highPriorityGesture(TapGesture().onEnded { onStrike(true) })
                .accessibilityIdentifier("rock-weak-point")
                .accessibilityLabel(DeepMineStrings.text(.shaftWeakPoint))
                .accessibilityAddTraits(.isButton)
        }
    }

    /// The cut sides of the shaft, drawn over every band so the column reads as one hole
    /// rather than a stack of unrelated stripes.
    private var shaftWalls: some View {
        HStack {
            wall
            Spacer()
            wall
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var wall: some View {
        Rectangle()
            .fill(DeepMinePalette.shale.color)
            .frame(width: 7)
            .overlay(alignment: .center) {
                Rectangle()
                    .fill(DeepMinePalette.limestone.color.opacity(0.18))
                    .frame(width: 1)
            }
    }

    // MARK: Derived

    var height: CGFloat {
        ShaftGeometry.height(of: layer.position)
    }

    private var damageStage: Int {
        layer.position == .current
            ? layer.segment.damageStage(
                remaining: layer.segment.maximumIntegrity * (1 - brokenFraction)
            )
            : 1
    }

    private var fractureIntensity: FractureIntensity {
        switch damageStage {
        case 2: .light
        case 3: .medium
        default: .heavy
        }
    }
}
