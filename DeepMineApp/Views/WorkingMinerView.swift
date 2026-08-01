import SwiftUI

/// A miner whose generated pickaxe moves independently from the body.
///
/// In the shaft, `strikeSignal` drives one interruptible down-stroke per hit. Other
/// mining surfaces keep a slow repeating swing so automation never reads as paused.
struct WorkingMinerView: View {
    let isWorking: Bool
    var intensity: Double = 0
    var strikeSignal = 0
    var repeatsWhenIdle = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var passiveSwinging = false
    @State private var striking = false

    private var clampedIntensity: Double { min(1, max(0, intensity)) }
    private var repeats: Bool { isWorking && repeatsWhenIdle && !reduceMotion }
    private var swingDuration: Double { 0.46 - clampedIntensity * 0.2 }
    private var readyAngle: Double { -21 - clampedIntensity * 5 }
    private var impactAngle: Double { reduceMotion ? 10 : 63 + clampedIntensity * 9 }

    var body: some View {
        ZStack {
            Image("MinerSprite")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 58, height: 58)
                .offset(x: -15, y: 13)

            GameArtView(entry: GameArtCatalog.miningPickaxe, size: 74)
                .rotationEffect(
                    .degrees(striking || passiveSwinging ? impactAngle : readyAngle),
                    anchor: UnitPoint(x: 0.16, y: 0.82)
                )
                .offset(x: 10, y: -8)
                .animation(
                    repeats
                        ? .easeInOut(duration: swingDuration).repeatForever(autoreverses: true)
                        : nil,
                    value: passiveSwinging
                )
        }
        .frame(width: 92, height: 92)
        .onAppear { passiveSwinging = repeats }
        .onChange(of: repeats) { _, next in passiveSwinging = next }
        .task(id: strikeSignal) {
            guard isWorking, strikeSignal > 0 else { return }
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.08)) { striking = true }
                try? await Task.sleep(for: .milliseconds(75))
                withAnimation(.easeOut(duration: 0.1)) { striking = false }
                return
            }
            withAnimation(.easeIn(duration: 0.075)) { striking = true }
            try? await Task.sleep(for: .milliseconds(85))
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.78)) {
                striking = false
            }
        }
        .accessibilityHidden(true)
    }
}
