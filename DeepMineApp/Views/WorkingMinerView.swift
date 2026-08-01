import SwiftUI

/// The miner swinging a pick, built from the single sprite by rocking and bobbing it.
///
/// Spec §10.2 rules out repeating animation on the Live Activity, not in the app. This
/// screen is the one place a player watches the mine work, and a still image there reads
/// as a paused game.
struct WorkingMinerView: View {
    let isWorking: Bool
    var intensity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swinging = false

    private var animates: Bool { isWorking && !reduceMotion }
    private var clampedIntensity: Double { min(1, max(0, intensity)) }
    private var swingDuration: Double { 0.42 - clampedIntensity * 0.18 }

    var body: some View {
        Image("MinerSprite")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            // Rotating about the lower trailing corner reads as a shoulder pivot rather
            // than the whole figure tipping over.
            .rotationEffect(
                .degrees(swinging ? -7 - clampedIntensity * 5 : 4 + clampedIntensity * 2),
                anchor: UnitPoint(x: 0.68, y: 0.85)
            )
            .offset(y: swinging ? -2 - clampedIntensity : 1)
            .animation(
                animates
                    ? .easeInOut(duration: swingDuration).repeatForever(autoreverses: true)
                    : .default,
                value: swinging
            )
            .onAppear { swinging = animates }
            .onChange(of: animates) { _, next in swinging = next }
    }
}
