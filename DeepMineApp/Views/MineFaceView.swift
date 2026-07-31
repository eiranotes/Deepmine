import DeepMineCore
import SwiftUI

/// The rock section of the mine screen: tap it, break it, collect ore.
///
/// Embedded at the top of `MineHomeView` rather than owning a screen, because in an idle
/// clicker the tap target and the progression panels belong on one surface.
///
/// This view owns the automation tick. It is the only place a timer advances the mine, so
/// on-screen progress and offline catch-up cannot disagree about how fast the mine runs.
@MainActor
struct MineFaceView: View {
    @Binding var player: PlayerState
    let feedback: GameFeedback
    var onPersist: (PlayerState) -> Void = { _ in }

    @State private var generator = SeededGenerator(seed: UInt64.random(in: .min ... .max))
    @State private var struckWeakPoint = false
    @State private var floatingGains: [FloatingGain] = []
    @State private var lastTick = Date()

    private let tick = Timer.publish(
        every: Balance.automationStepSeconds,
        on: .main,
        in: .common
    ).autoconnect()

    private var power: StrikePower { MiningLoop.power(for: player) }

    var body: some View {
        VStack(spacing: 10) {
            header
            rock
            progress
        }
        .frame(maxWidth: .infinity)
        .onReceive(tick) { now in
            let elapsed = now.timeIntervalSince(lastTick)
            lastTick = now
            guard elapsed > 0, power.isAutomated else { return }
            let update = MiningLoop.advance(seconds: elapsed, in: &player)
            if update.brokeSomething { announce(update, isTap: false) }
        }
    }

    private var header: some View {
        HStack {
            Text("\(DeepMineStrings.text(.gameDepth)) \(player.depthMeters)m")
                .font(.headline.monospacedDigit())
                .accessibilityIdentifier("mine-depth")
            Spacer()
            if power.isAutomated {
                Text("\(DeepMineNumberFormatter.string(power.damagePerSecond.doubleValue))/s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.7))
                    .accessibilityIdentifier("mine-automation-rate")
            }
        }
    }

    private var rock: some View {
        ZStack {
            RockFaceView(
                face: player.mineFace,
                isStruck: struckWeakPoint,
                onStrike: strike(onWeakPoint:)
            )
            ForEach(floatingGains) { gain in
                Text(gain.text)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(
                        gain.isCritical
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.limestone.color
                    )
                    .offset(x: gain.offsetX, y: gain.offsetY)
                    .opacity(gain.opacity)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var progress: some View {
        VStack(spacing: 6) {
            DeepMineProgressRail(
                value: player.mineFace.brokenFraction,
                total: 1,
                accessibilityLabel: DeepMineStrings.text(.mineIntegrity)
            )
            .accessibilityIdentifier("mine-integrity")
            if player.mineFace.segment.isSeam {
                Text(DeepMineStrings.text(.mineSeam))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("mine-seam")
            }
        }
    }

    private func strike(onWeakPoint: Bool) {
        struckWeakPoint = onWeakPoint
        let update = MiningLoop.strike(
            hitWeakPoint: onWeakPoint,
            using: &generator,
            in: &player
        )
        announce(update, isTap: true)
    }

    private func announce(_ update: MineFaceUpdate, isTap: Bool) {
        if isTap {
            feedback.play(update.wasCritical ? .criticalStrike : .strike)
        }
        if update.brokeSomething {
            feedback.play(update.seamsBroken > 0 ? .seamBroken : .segmentBroken)
            onPersist(player)
        }
        guard isTap || update.brokeSomething else { return }
        show(FloatingGain(
            text: "+\(DeepMineNumberFormatter.string(update.oreGained.doubleValue))",
            isCritical: update.wasCritical,
            offsetX: Double.random(in: -40...40)
        ))
    }

    private func show(_ gain: FloatingGain) {
        floatingGains.append(gain)
        withAnimation(.easeOut(duration: 0.7)) {
            if let index = floatingGains.firstIndex(where: { $0.id == gain.id }) {
                floatingGains[index].offsetY = -90
                floatingGains[index].opacity = 0
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            floatingGains.removeAll { $0.id == gain.id }
        }
    }
}

struct FloatingGain: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isCritical: Bool
    var offsetX: Double
    var offsetY: Double = 0
    var opacity: Double = 1
}
