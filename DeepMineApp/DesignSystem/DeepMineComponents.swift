import SwiftUI

enum DeepMineMetalButtonRole: CaseIterable, Sendable {
    case primary
    case secondary
    case warning
    case safety

    var fill: DeepMinePigment {
        switch self {
        case .primary: DeepMinePalette.brass
        case .secondary, .warning: DeepMinePalette.shale
        case .safety: DeepMinePalette.coal
        }
    }

    var foreground: DeepMinePigment {
        switch self {
        case .primary: DeepMinePalette.coal
        case .secondary, .safety: DeepMinePalette.limestone
        case .warning: DeepMinePalette.brass
        }
    }

    var rim: DeepMinePigment {
        switch self {
        case .primary: DeepMinePalette.coal
        case .secondary: DeepMinePalette.limestone
        case .warning, .safety: DeepMinePalette.brass
        }
    }

    var edge: DeepMinePigment {
        self == .safety ? DeepMinePalette.brass : DeepMinePalette.coal
    }
}

struct DeepMineMetalButtonStyle: ButtonStyle {
    let role: DeepMineMetalButtonRole

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(role.foreground.color.opacity(isEnabled ? 1 : 0.46))
            .frame(maxWidth: .infinity, minHeight: DeepMineMetrics.buttonHeight)
            .padding(.horizontal, 16)
            .background(
                role.fill.color.opacity(isEnabled ? 1 : 0.30),
                in: RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
            )
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                        .stroke(
                            contrast == .increased
                                ? DeepMinePalette.limestone.color
                                : role.rim.color.opacity(role == .secondary ? 0.48 : 1),
                            lineWidth: contrast == .increased ? 2 : 1
                        )
                    DeepMineRivets(color: role.foreground.color.opacity(0.30))
                        .padding(5)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                    .fill(role.edge.color)
                    .offset(y: DeepMineMetrics.metalDepth)
            }
            .offset(y: DeepMineMotion.pressOffset(
                isPressed: configuration.isPressed,
                reduceMotion: reduceMotion
            ))
            .padding(.bottom, DeepMineMetrics.metalDepth)
            .animation(
                DeepMineMotion.pressAnimation(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
            .contentShape(Rectangle())
    }
}

struct DeepMineActionLabel: View {
    let titleKey: DeepMineStringKey
    let detailKey: DeepMineStringKey?
    let symbol: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.body.weight(.bold))
                .frame(width: 25)
            VStack(alignment: .leading, spacing: 2) {
                Text(DeepMineStrings.text(titleKey))
                if let detailKey {
                    Text(DeepMineStrings.text(detailKey))
                        .font(.caption)
                        .opacity(0.74)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DeepMineRivetedPanel<Content: View>: View {
    @ViewBuilder let content: Content

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        content
            .padding(DeepMineMetrics.panelPadding)
            .background(
                DeepMinePalette.shale.color,
                in: RoundedRectangle(cornerRadius: DeepMineMetrics.panelCornerRadius)
            )
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: DeepMineMetrics.panelCornerRadius)
                        .stroke(
                            DeepMinePalette.limestone.color.opacity(contrast == .increased ? 1 : 0.28),
                            lineWidth: contrast == .increased ? 2 : 1
                        )
                    DeepMineRivets(color: DeepMinePalette.limestone.color.opacity(0.22))
                        .padding(7)
                }
            }
    }
}

struct DeepMineRivets: View {
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

struct DeepMineStatusMarker: View {
    let status: DeepMineStatus
    /// Lets a screen name the state in its own vocabulary while keeping the shape,
    /// pigment and symbol of the shared status language.
    var titleKey: DeepMineStringKey?

    var body: some View {
        let label = DeepMineStrings.text(titleKey ?? status.titleKey)
        Label(label, systemImage: status.symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(status.isFilled ? DeepMinePalette.coal.color : status.pigment.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                status.isFilled ? status.pigment.color : DeepMinePalette.coal.color,
                in: RoundedRectangle(cornerRadius: DeepMineMetrics.badgeCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DeepMineMetrics.badgeCornerRadius)
                    .stroke(status.pigment.color.opacity(status.isFilled ? 1 : 0.56))
            }
            .accessibilityLabel(label)
    }
}

struct DeepMineMineToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(DeepMineMotion.pressAnimation(reduceMotion: reduceMotion)) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer(minLength: 8)
                lever(isOn: configuration.isOn)
            }
        }
        .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
    }

    private func lever(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(DeepMinePalette.coal.color)
                .frame(width: DeepMineMetrics.toggleWidth, height: DeepMineMetrics.toggleHeight)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            (isOn ? DeepMinePalette.brass : DeepMinePalette.limestone).color,
                            lineWidth: 1
                        )
                }
            RoundedRectangle(cornerRadius: 3)
                .fill((isOn ? DeepMinePalette.brass : DeepMinePalette.limestone).color)
                .frame(width: 20, height: 20)
                .overlay {
                    HStack(spacing: 3) {
                        Circle().frame(width: 3, height: 3)
                        Circle().frame(width: 3, height: 3)
                    }
                    .foregroundStyle(DeepMinePalette.coal.color.opacity(0.54))
                }
                .padding(4)
        }
        .accessibilityHidden(true)
    }
}
