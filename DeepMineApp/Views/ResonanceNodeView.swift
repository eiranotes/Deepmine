import DeepMineCore
import SwiftUI

/// The claimable resonance node, and the surge readout after it is taken.
///
/// Deliberately a real button rather than a tap anywhere on the shaft: the reward is for
/// noticing and reaching, and a node that could be collected by the taps the player was
/// already making would be indistinguishable from ordinary income (D-057).
struct ResonanceNodeView: View {
    let state: ResonanceNodeState
    let now: Date
    let onClaim: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        switch state.phase {
        case .active:
            node
        case .claimed where state.isBoostActive(at: now):
            surge
        default:
            EmptyView()
        }
    }

    private var node: some View {
        Button(action: onClaim) {
            GameArtView(entry: GameArtCatalog.resonanceNode, size: 44)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
                .scaleEffect(pulse && !reduceMotion ? 1.08 : 1)
                .shadow(color: DeepMinePalette.brass.color.opacity(0.85), radius: pulse ? 12 : 6)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("resonance-node")
        .accessibilityLabel(DeepMineStrings.text(.resonanceNodeClaim))
        .accessibilityAddTraits(.isButton)
        .task(id: state.cycle) {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.62).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var surge: some View {
        Text(String(
            format: DeepMineStrings.text(.resonanceNodeBoost),
            "\(state.boostSecondsRemaining(at: now))"
        ))
        .font(.caption2.monospacedDigit().weight(.black))
        .foregroundStyle(DeepMinePalette.coal.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(DeepMinePalette.brass.color, in: Capsule())
        .accessibilityIdentifier("resonance-surge")
    }
}
