import SwiftUI

struct ProbeStepRow<Accessory: View>: View {
    let index: String
    let title: String
    let detail: String
    @ViewBuilder let accessory: Accessory

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { rowLabel; Spacer(minLength: 8); accessory }
            VStack(alignment: .leading, spacing: 10) { rowLabel; accessory }
        }
        .padding(.vertical, 2)
    }

    private var rowLabel: some View {
        HStack(spacing: 11) {
            Text(index)
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(ProbePalette.abyss)
                .frame(width: 28, height: 28)
                .background(ProbePalette.brass, in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ProbePalette.highlight)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ProbeInstrumentRow<Actions: View>: View {
    let symbol: String
    let title: String
    let detail: String
    let state: ProbeDisplayState
    @ViewBuilder let actions: Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 11) {
                    instrumentLabel
                    Spacer()
                    ProbeStatusChip(state: state)
                }
                VStack(alignment: .leading, spacing: 9) {
                    instrumentLabel
                    ProbeStatusChip(state: state)
                }
            }
            actions
        }
    }

    private var instrumentLabel: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(state.color)
                .frame(width: 34, height: 34)
                .background(state.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ProbePalette.highlight)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ProbeAdaptiveActions<First: View, Second: View>: View {
    @ViewBuilder let first: First
    @ViewBuilder let second: Second

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 9) {
                first.frame(maxWidth: .infinity)
                second.frame(maxWidth: .infinity)
            }
            VStack(spacing: 9) {
                first.frame(maxWidth: .infinity)
                second.frame(maxWidth: .infinity)
            }
        }
    }
}

struct ProbeInlineAlert: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ProbePalette.brass)
            VStack(alignment: .leading, spacing: 4) {
                Text("준비 중 문제가 생겼어요")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ProbePalette.brass)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(ProbePalette.chalk)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 4)
            Button("닫기", systemImage: "xmark", action: dismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(ProbePressButtonStyle(role: .secondary))
        }
        .padding(14)
        .background(ProbePalette.brass.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
        .overlay {
            RoundedRectangle(cornerRadius: 11)
                .stroke(ProbePalette.brass.opacity(0.38), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}
