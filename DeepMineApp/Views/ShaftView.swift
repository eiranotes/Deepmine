import DeepMineCore
import SwiftUI

/// The mine, seen from the side.
///
/// Depth is the number this game is about, so it is drawn as a place instead of a label:
/// old passage above, the head travelling through one continuous geological body, and
/// future rock fading into darkness below.
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
    /// same geology and geometry — with the clock and the dice held.
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
    private var scene: ShaftScene { ShaftSceneEngine.scene(for: player) }

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
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                DeepMinePalette.coal.color
                ShaftGeologyView(
                    scene: scene,
                    player: player,
                    isStruck: struckWeakPoint,
                    onStrike: strike(onWeakPoint:)
                )
                if player.mineFace.segmentIndex == 0 { surfaceCanopy }
                depthRuler(width: proxy.size.width)
                regionPlates(width: proxy.size.width)
                ShaftEffectsView(
                    gains: floatingGains,
                    debris: debrisBursts,
                    reduceMotion: reduceMotion
                )
                .position(
                    x: proxy.size.width / 2,
                    y: ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
                )
            }
        }
        .frame(height: ShaftGeometry.columnHeight(for: scene))
        .clipShape(RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                .stroke(DeepMinePalette.limestone.color.opacity(0.28))
        }
        // Marks are overlays, so the scene remains centred instead of being pushed right
        // by a ruler column.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mine-shaft")
        .animation(
            reduceMotion ? nil : .interactiveSpring(
                response: 0.34,
                dampingFraction: 1,
                blendDuration: 0.08
            ),
            value: player.mineFace.segmentIndex
        )
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.16),
            value: player.mineFace.brokenFraction
        )
    }

    private var surfaceCanopy: some View {
        GeometryReader { proxy in
            GameArtView(entry: GameArtCatalog.shaftSurface, fill: proxy.size)
        }
        .frame(height: 54)
        .opacity(0.88)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func depthRuler(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(ShaftGeometry.depthMarks(in: scene), id: \.self) { depth in
                HStack(spacing: 3) {
                    Rectangle()
                        .fill(DeepMinePalette.limestone.color.opacity(0.45))
                        .frame(width: 8, height: 1)
                    Text("\(depth)m")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(DeepMinePalette.coal.color.opacity(0.68), in: Capsule())
                .position(
                    x: 30,
                    y: ShaftGeometry.y(for: Double(depth), in: scene)
                )
            }
            Text("\(Int(scene.headDepthMeters.rounded()))m")
                .font(.caption2.monospacedDigit().weight(.black))
                .foregroundStyle(DeepMinePalette.coal.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(DeepMinePalette.brass.color, in: Capsule())
                .position(
                    x: 31,
                    y: ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
                )
        }
        .frame(width: width)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func regionPlates(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(scene.strata.filter(\.isRegionEntrance)) { stratum in
                if stratum.startDepthMeters > 0 {
                    Text(DeepMineStrings.text(DeepMineProgressLabels.regionKey(stratum.region)))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DeepMinePalette.coal.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(DeepMinePalette.brass.color, in: Capsule())
                        .position(
                            x: width - 46,
                            y: ShaftGeometry.y(for: stratum.startDepthMeters, in: scene) + 12
                        )
                        .accessibilityIdentifier("shaft-region-\(stratum.region.rawValue)")
                }
            }
        }
        .frame(width: width)
        .allowsHitTesting(false)
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
        let tier = EquipmentEngine.visualTier(level: player.equipment.drill)
        let wideBonus = player.equipmentModifications.drill == .drillWide ? 2 : 0
        let impactBonus = player.equipmentModifications.drill == .drillImpact ? 1 : 0
        let burst = DebrisBurst(
            isLarge: isLarge,
            density: 3 + tier * 2 + wideBonus + impactBonus
        )
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
