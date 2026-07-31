import DeepMineCore
import SwiftUI

/// The tap target. Everything else in the clicker exists to make this rock break faster.
struct RockFaceView: View {
    let face: MineFaceState
    let isStruck: Bool
    let onStrike: (Bool) -> Void

    @State private var shake = false

    private var regionID: String { face.region.rawValue }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                GameArtView(
                    entry: GameArtCatalog.rockFace(region: regionID, stage: face.damageStage),
                    size: side
                )

                if face.damageStage > 1 {
                    GameArtView(entry: GameArtCatalog.fracture(intensity: fractureIntensity), size: side)
                        .opacity(0.9)
                        .allowsHitTesting(false)
                }

                if let point = face.segment.weakPoint {
                    GameArtView(entry: GameArtCatalog.weakPoint(isStruck: isStruck), size: side * 0.2)
                        .position(
                            x: side * point.unitX,
                            y: side * point.unitY
                        )
                        .onTapGesture { onStrike(true) }
                        .accessibilityIdentifier("rock-weak-point")
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(x: shake ? -6 : 0)
            .contentShape(Rectangle())
            .onTapGesture { onStrike(false) }
        }
        .onChange(of: face.segmentIndex) { _, _ in
            // A break is the one moment the rock should visibly react.
            withAnimation(.easeInOut(duration: 0.06).repeatCount(3, autoreverses: true)) {
                shake = true
            }
            shake = false
        }
        .accessibilityIdentifier("rock-face")
        .accessibilityLabel(Text("\(DeepMineStrings.text(.gameDepth)) \(face.depthMeters)m"))
    }

    private var fractureIntensity: FractureIntensity {
        switch face.damageStage {
        case 2: .light
        case 3: .medium
        default: .heavy
        }
    }
}
