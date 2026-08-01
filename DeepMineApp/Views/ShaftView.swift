import DeepMineCore
import SwiftUI

/// The mine, seen from the side.
///
/// Depth is the number this game is about, so it is drawn as a place instead of a label:
/// broken shaft above, the face being worked in the middle, unbroken rock fading into the
/// dark below. Breaking through moves the whole column up by one band, which is the
/// player descending.
///
/// This view owns the automation tick. It is the only place a timer advances the mine, so
/// on-screen progress and offline catch-up cannot disagree about how fast the mine runs.
@MainActor
struct ShaftView: View {
    @Binding var player: PlayerState
    let feedback: GameFeedback
    var onPersist: (PlayerState) -> Void = { _ in }
    /// Fixtures render the shaft for screen tests, where a mine that advances on a timer
    /// would make every capture different. A still shaft is still the real view — the
    /// same layers, the same geometry — with the clock and the dice held.
    var isLive = true

    @State private var generator = SeededGenerator(seed: UInt64.random(in: .min ... .max))
    @State private var struckWeakPoint = false
    @State private var floatingGains: [FloatingGain] = []
    @State private var debrisBursts: [DebrisBurst] = []
    @State private var lastTick = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tick = Timer.publish(
        every: Balance.automationStepSeconds,
        on: .main,
        in: .common
    ).autoconnect()

    private var power: StrikePower { MiningLoop.power(for: player) }
    private var layers: [ShaftLayer] { ShaftVision.layers(for: player) }
    private var face: Int { player.mineFace.segmentIndex }

    var body: some View {
        VStack(spacing: 10) {
            ShaftHUDView(player: player, power: power)
            shaft
        }
        .frame(maxWidth: .infinity)
        .onReceive(tick) { now in
            guard isLive else { return }
            let elapsed = MiningLoop.unsettledVisibleSeconds(
                lastTick: lastTick,
                lastSettledAt: player.lastSettledAt,
                now: now
            )
            lastTick = now
            advance(by: elapsed, at: now)
        }
    }

    // MARK: Shaft column

    private var shaft: some View {
        ZStack(alignment: .top) {
            DeepMinePalette.coal.color
            if face == 0 { surfaceCanopy }
            ForEach(layers) { layer in
                row(layer)
                    .offset(y: ShaftGeometry.offset(of: layer.segment.index, face: face))
            }
            ShaftEffectsView(
                gains: floatingGains,
                debris: debrisBursts,
                reduceMotion: reduceMotion
            )
            .offset(y: ShaftGeometry.faceTop)
        }
        .frame(height: ShaftGeometry.columnHeight(
            below: ShaftVision.visibleLayersBelow(lampLevel: player.equipment.lamp)
        ))
        .clipShape(RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                .stroke(DeepMinePalette.limestone.color.opacity(0.28))
        }
        // The column is a scene, not a list: the layers below the lamp are dark on
        // purpose, so a screen reader gets the one fact the picture is carrying.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mine-shaft")
        .animation(
            reduceMotion ? nil : .interactiveSpring(
                response: 0.34,
                dampingFraction: 1,
                blendDuration: 0.08
            ),
            value: face
        )
    }

    private var surfaceCanopy: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 50)
            GeometryReader { proxy in
                GameArtView(entry: GameArtCatalog.shaftSurface, fill: proxy.size)
            }
        }
        .frame(height: ShaftGeometry.faceTop)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func row(_ layer: ShaftLayer) -> some View {
        HStack(spacing: 0) {
            depthTick(layer)
            ShaftLayerView(
                layer: layer,
                isStruck: struckWeakPoint,
                brokenFraction: layer.position == .current ? player.mineFace.brokenFraction : 0,
                onStrike: strike(onWeakPoint:)
            )
        }
        .overlay(alignment: .topTrailing) {
            if layer.isRegionEntrance, layer.segment.index > 0 {
                regionPlate(layer)
            }
        }
    }

    /// The ruler down the left edge. Numbers only where they mean something — every band
    /// labelled would be a wall of digits four metres apart.
    private func depthTick(_ layer: ShaftLayer) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Bands are four metres apart. A 20m cadence stays legible and matches the
            // visual specification; the current face is always labelled between marks.
            if layer.position == .current
                || layer.depthMeters.isMultiple(of: 20) {
                Text("\(layer.depthMeters)m")
                    .font(.caption2.monospacedDigit().weight(layer.position == .current ? .bold : .regular))
                    .foregroundStyle(
                        layer.position == .current
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.limestone.color.opacity(0.5)
                    )
            }
        }
        .frame(width: 44, alignment: .trailing)
        .padding(.trailing, 6)
        .frame(height: ShaftGeometry.height(of: layer.position), alignment: .top)
        .padding(.top, 3)
        .accessibilityHidden(true)
    }

    private func regionPlate(_ layer: ShaftLayer) -> some View {
        Text(DeepMineStrings.text(DeepMineProgressLabels.regionKey(layer.segment.region)))
            .font(.caption2.weight(.bold))
            .foregroundStyle(DeepMinePalette.coal.color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(DeepMinePalette.brass.color, in: Capsule())
            .padding(.trailing, 12)
            .accessibilityIdentifier("shaft-region-\(layer.segment.region.rawValue)")
    }

    // MARK: Actions

    private func strike(onWeakPoint: Bool) {
        struckWeakPoint = onWeakPoint
        let update = MiningLoop.strike(
            hitWeakPoint: onWeakPoint,
            using: &generator,
            in: &player
        )
        announce(update, isTap: true)
        guard onWeakPoint else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            struckWeakPoint = false
        }
    }

    /// One automation step. Runs even when nothing is automated, because the impact meter
    /// decays with time and a player who has not bought a cart still has one.
    ///
    /// Passing the tick's own timestamp keeps the settlement mark level with the screen,
    /// so time spent watching the mine is not paid again as offline time on the next
    /// return.
    private func advance(by elapsed: TimeInterval, at now: Date) {
        guard elapsed > 0 else { return }
        let update = MiningLoop.advance(seconds: elapsed, at: now, in: &player)
        if update.brokeSomething { announce(update, isTap: false) }
    }

    private func announce(_ update: MineFaceUpdate, isTap: Bool) {
        if isTap {
            feedback.play(update.wasCritical ? .criticalStrike : .strike)
        }
        if update.brokeSomething {
            feedback.play(update.seamsBroken > 0 ? .seamBroken : .segmentBroken)
        }
        // Persisting on every tap is a write per frame; persisting only on a break loses
        // a whole segment of tapping when the app dies mid-face. This writes on a break
        // and lets the caller throttle the rest.
        onPersist(player)
        if update.brokeSomething {
            showDebris(isLarge: update.seamsBroken > 0)
            show(FloatingGain(
                text: "+\(DeepMineNumberFormatter.string(update.oreGained.doubleValue))",
                kind: .ore,
                offsetX: Double.random(in: -34...34)
            ))
        } else if isTap {
            show(FloatingGain(
                text: "−\(DeepMineNumberFormatter.string(update.damage.doubleValue))",
                kind: update.wasCritical ? .critical : .damage,
                offsetX: Double.random(in: -42...42)
            ))
        }
    }

    private func show(_ gain: FloatingGain) {
        floatingGains.append(gain)
        guard !reduceMotion else {
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.linear(duration: 0.18)) {
                    if let index = floatingGains.firstIndex(where: { $0.id == gain.id }) {
                        floatingGains[index].opacity = 0
                    }
                }
                try? await Task.sleep(for: .milliseconds(200))
                floatingGains.removeAll { $0.id == gain.id }
            }
            return
        }
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

    private func showDebris(isLarge: Bool) {
        let burst = DebrisBurst(isLarge: isLarge)
        debrisBursts.append(burst)
        guard !reduceMotion else {
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.linear(duration: 0.16)) {
                    if let index = debrisBursts.firstIndex(where: { $0.id == burst.id }) {
                        debrisBursts[index].opacity = 0
                    }
                }
                try? await Task.sleep(for: .milliseconds(180))
                debrisBursts.removeAll { $0.id == burst.id }
            }
            return
        }
        withAnimation(.easeOut(duration: 0.42)) {
            if let index = debrisBursts.firstIndex(where: { $0.id == burst.id }) {
                debrisBursts[index].progress = 1
                debrisBursts[index].opacity = 0
            }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(480))
            debrisBursts.removeAll { $0.id == burst.id }
        }
    }
}
