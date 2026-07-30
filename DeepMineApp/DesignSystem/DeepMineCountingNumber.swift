import SwiftUI

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
