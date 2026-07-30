import SwiftUI

struct DeepMineProgressRail: View {
    let value: Double
    let total: Double
    let accessibilityLabel: String

    private var fraction: Double {
        guard total > 0, value.isFinite, total.isFinite else { return 0 }
        return min(1, max(0, value / total))
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawnFraction: Double = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(DeepMinePalette.coal.color)
                RoundedRectangle(cornerRadius: 3)
                    .fill(DeepMinePalette.brass.color)
                    .frame(width: proxy.size.width * drawnFraction)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(DeepMinePalette.limestone.color.opacity(0.36), lineWidth: 1)
            }
        }
        .frame(height: 9)
        // Filling on appear turns a static bar into a readable amount of progress. The
        // accessibility value always reports the real fraction, never the drawn one.
        .onAppear { setFraction(fraction, animated: !reduceMotion) }
        .onChange(of: fraction) { _, next in setFraction(next, animated: !reduceMotion) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }

    private func setFraction(_ next: Double, animated: Bool) {
        guard animated else {
            drawnFraction = next
            return
        }
        withAnimation(.easeOut(duration: 0.55)) { drawnFraction = next }
    }
}

struct DeepMineEquipmentDisplay: Equatable, Sendable {
    let titleKey: DeepMineStringKey
    let symbol: String
    let level: Int
    let detail: String
    let status: DeepMineStatus
}

struct DeepMineEquipmentRow: View {
    let equipment: DeepMineEquipmentDisplay
    var accessory: AnyView?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { label; Spacer(minLength: 8); trailing }
            VStack(alignment: .leading, spacing: 10) { label; trailing }
        }
        .frame(minHeight: DeepMineMetrics.minimumHitTarget)
        .accessibilityElement(children: .contain)
    }

    private var label: some View {
        HStack(spacing: 11) {
            Image(systemName: equipment.symbol)
                .font(.body.weight(.bold))
                .foregroundStyle(equipment.status.pigment.color)
                .frame(width: 44, height: 44)
                .background(
                    DeepMinePalette.coal.color,
                    in: RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(DeepMineStrings.text(equipment.titleKey))
                    .font(.subheadline.weight(.semibold))
                Text(equipment.detail)
                    .font(.caption)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var trailing: some View {
        if let accessory {
            accessory
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                Text("Lv. \(equipment.level)")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                DeepMineStatusMarker(status: equipment.status)
            }
        }
    }
}

extension View {
    func deepMineHitTarget() -> some View {
        frame(
            minWidth: DeepMineMetrics.minimumHitTarget,
            minHeight: DeepMineMetrics.minimumHitTarget
        )
        .contentShape(Rectangle())
    }
}
