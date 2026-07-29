import SwiftUI

struct ProbePressButtonStyle: ButtonStyle {
    let role: ProbeButtonRole

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(role.foreground.opacity(isEnabled ? 1 : 0.46))
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .background(
                role.fill.opacity(isEnabled ? 1 : 0.30),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            contrast == .increased ? ProbePalette.chalk : role.rim,
                            lineWidth: contrast == .increased ? 2 : 1
                        )
                    ProbeRivetCorners(color: role.foreground.opacity(isEnabled ? 0.30 : 0.12))
                        .padding(5)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(role.edge.opacity(isEnabled ? 1 : 0.24))
                    .offset(y: 4)
            }
            .offset(y: configuration.isPressed ? 3 : 0)
            .padding(.bottom, 4)
            .animation(
                reduceMotion ? nil : .interactiveSpring(response: 0.18, dampingFraction: 1),
                value: configuration.isPressed
            )
            .contentShape(Rectangle())
    }
}

private struct ProbeRivetCorners: View {
    let color: Color

    var body: some View {
        VStack {
            HStack { rivet; Spacer(); rivet }
            Spacer()
            HStack { rivet; Spacer(); rivet }
        }
        .accessibilityHidden(true)
    }

    private var rivet: some View {
        Circle().fill(color).frame(width: 3, height: 3)
    }
}

struct ProbeActionLabel: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.body.weight(.bold))
                .frame(width: 25)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lineLimit(2)
                Text(detail)
                    .font(.caption)
                    .opacity(0.74)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProbeStatusChip: View {
    let state: ProbeDisplayState

    var body: some View {
        Label(state.label, systemImage: state.symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(state.isFilled ? ProbePalette.coal : state.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                state.isFilled ? state.color : ProbePalette.coal.opacity(0.52),
                in: RoundedRectangle(cornerRadius: 5)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(state.color.opacity(state.isFilled ? 1 : 0.56), lineWidth: 1)
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel("준비 상태: \(state.label)")
    }
}

struct ProbeMineToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(
                reduceMotion ? nil : .interactiveSpring(response: 0.2, dampingFraction: 1)
            ) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer(minLength: 8)
                lever(isOn: configuration.isOn)
            }
        }
        .buttonStyle(ProbePressButtonStyle(role: .secondary))
        .accessibilityValue(configuration.isOn ? "열림" : "닫힘")
    }

    private func lever(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(ProbePalette.coal)
                .frame(width: 52, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isOn ? ProbePalette.brass : ProbePalette.rockLight, lineWidth: 1)
                }
            RoundedRectangle(cornerRadius: 3)
                .fill(isOn ? ProbePalette.brass : ProbePalette.metal)
                .frame(width: 20, height: 20)
                .overlay {
                    HStack(spacing: 3) {
                        Circle().frame(width: 3, height: 3)
                        Circle().frame(width: 3, height: 3)
                    }
                    .foregroundStyle(ProbePalette.coal.opacity(0.54))
                }
                .padding(4)
        }
        .accessibilityHidden(true)
    }
}

struct ProbeModule<Content: View>: View {
    let stage: String
    let title: String
    let subtitle: String
    let symbol: String
    let state: ProbeDisplayState
    @ViewBuilder let content: Content

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    missionMark
                    heading
                    Spacer(minLength: 8)
                    ProbeStatusChip(state: state)
                }
                VStack(alignment: .leading, spacing: 11) {
                    HStack(spacing: 12) {
                        missionMark
                        heading
                    }
                    ProbeStatusChip(state: state)
                }
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(ProbePalette.highlight)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
        .padding(17)
        .background(ProbePalette.rockDeep, in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(
                        contrast == .increased ? ProbePalette.chalk : ProbePalette.rockLight,
                        lineWidth: contrast == .increased ? 2 : 1
                    )
                ProbeRivetCorners(color: ProbePalette.limestone.opacity(0.22))
                    .padding(7)
            }
        }
    }

    private var missionMark: some View {
        Image(systemName: symbol)
            .font(.title3.weight(.bold))
            .foregroundStyle(ProbePalette.brass)
            .frame(width: 44, height: 44)
            .background(ProbePalette.coal, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ProbePalette.brass.opacity(0.62), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(stage)
                .font(.caption.weight(.bold))
                .foregroundStyle(ProbePalette.brass)
            Text(title)
                .font(.headline.weight(.bold))
        }
    }
}
