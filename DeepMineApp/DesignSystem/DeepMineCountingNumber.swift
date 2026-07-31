import SwiftUI

enum OreHaulPresentation {
    static func chunkCount(for ore: Double) -> Int {
        guard ore.isFinite, ore > 0 else { return 0 }
        let magnitude = Int(floor(log10(max(1, ore)))) + 2
        return min(9, max(3, magnitude))
    }
}

/// A number that counts up to its value instead of appearing at it.
///
/// The haul is the payoff of a whole session, and a value that simply exists reads as a
/// label rather than a reward. Counting also gives the eye time to register the
/// magnitude, which matters once hauls reach six digits.
struct DeepMineCountingNumber: View {
    var value: Double
    var prefix: String = ""
    var font: Font = .body

    var body: some View {
        Text(prefix + DeepMineNumberFormatter.string(value))
            .font(font)
            .monospacedDigit()
            // Digit changes must not reflow the layout around the number.
            .contentTransition(.numericText())
    }
}

struct DeepMineOreHaulView: View {
    let ore: Double
    let reduceMotion: Bool
    let rewardID: UUID
    @State private var loaded = false

    private static let placements: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double)] = [
        (-5, -11, 14, -5), (-43, -12, 12, -8), (42, -11, 12, 11),
        (-22, -22, 10, 12), (20, -21, 10, 5), (-58, -20, 9, -7),
        (58, -21, 9, 7), (-34, -9, 11, 6), (30, -8, 11, -9)
    ]

    private var chunkCount: Int { OreHaulPresentation.chunkCount(for: ore) }

    var body: some View {
        ZStack {
            rail
            ForEach(0..<chunkCount, id: \.self) { index in
                oreChunk(index)
            }
            cart
        }
        .frame(maxWidth: .infinity, minHeight: 86)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DeepMineStrings.text(.gameOre))
        .accessibilityValue(DeepMineNumberFormatter.string(ore))
        .accessibilityIdentifier("return-ore-haul")
        .task(id: rewardID) {
            loaded = reduceMotion
            guard !reduceMotion else { return }
            loaded = false
            await Task.yield()
            loaded = true
        }
    }

    private var rail: some View {
        VStack(spacing: 9) {
            Rectangle()
            Rectangle()
        }
        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.13))
        .frame(height: 12)
        .offset(y: 34)
    }

    private var cart: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(DeepMinePalette.shale.color)
                .frame(width: 174, height: 34)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(DeepMinePalette.limestone.color.opacity(0.7), lineWidth: 1)
                }
                .offset(y: 11)
            Rectangle()
                .fill(DeepMinePalette.brass.color)
                .frame(width: 150, height: 3)
                .offset(y: -5)
            HStack(spacing: 106) {
                wheel
                wheel
            }
            .offset(y: 34)
        }
    }

    private var wheel: some View {
        Circle()
            .fill(DeepMinePalette.coal.color)
            .frame(width: 18, height: 18)
            .overlay {
                Circle()
                    .stroke(DeepMinePalette.limestone.color.opacity(0.72), lineWidth: 2)
            }
    }

    private func oreChunk(_ index: Int) -> some View {
        let placement = Self.placements[index]
        return RoundedRectangle(cornerRadius: 1)
            .fill(index.isMultiple(of: 3)
                ? DeepMinePalette.brass.color
                : DeepMinePalette.limestone.color)
            .frame(width: placement.size, height: placement.size * 0.82)
            .rotationEffect(.degrees(loaded ? placement.angle : placement.angle * -2))
            .offset(
                x: placement.x,
                y: loaded ? placement.y : -45 - CGFloat(index * 3)
            )
            .opacity(loaded ? 1 : 0)
            .animation(
                reduceMotion ? nil : .interactiveSpring(
                    response: 0.38,
                    dampingFraction: 0.78,
                    blendDuration: 0.08
                ).delay(Double(index) * 0.045),
                value: loaded
            )
    }
}

extension View {
    /// Counts a number up on appear, honouring Reduce Motion by landing on the final
    /// value immediately.
    func countingUp(
        to target: Double,
        reduceMotion: Bool,
        duration: TimeInterval = 0.9,
        into binding: Binding<Double>
    ) -> some View {
        onAppear {
            guard !reduceMotion, target > 0 else {
                binding.wrappedValue = target
                return
            }
            binding.wrappedValue = 0
            withAnimation(.easeOut(duration: duration)) {
                binding.wrappedValue = target
            }
        }
    }
}
