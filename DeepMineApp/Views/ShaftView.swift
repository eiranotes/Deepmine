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
    @State private var strikeSignal = 0
    /// Swing bookkeeping. Damage runs on the simulation step; the visible swing runs on its
    /// own readable period so automation cannot restart the actor mid-stroke (D-058).
    @State private var strikeVariant: StrikeVariant = .quick
    @State private var swingSequence = 0
    @State private var lastSwingAt: TimeInterval?
    @State private var lastManualStrikeAt: TimeInterval?
    @State var floatingGains: [FloatingGain] = []
    @State var debrisBursts: [DebrisBurst] = []
    @State var groundCollapses: [GroundCollapseBurst] = []
    @State private var lastTick = Date()
    /// Foreground-only intermittent reward. Kept in the view because it is a moment, not
    /// a saved fact: a node that expired while the app was closed was never offered.
    @State private var resonance = ResonanceNodeState()
    @State private var resonanceNow = Date()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let tick = Timer.publish(
        every: Balance.automationStepSeconds,
        on: .main,
        in: .common
    ).autoconnect()

    private var power: StrikePower { MiningLoop.power(for: player) }
    var scene: ShaftScene { ShaftSceneEngine.scene(for: player) }
    private var plant: MineInfrastructure {
        MineInfrastructureEngine.infrastructure(
            equipment: player.equipment,
            modifications: player.equipmentModifications
        )
    }

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
            resonanceNow = now
            resonance = ResonanceNodeEngine.advance(
                resonance,
                now: now,
                isForeground: scenePhase == .active,
                using: &generator
            )
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
                    strikeSignal: strikeSignal,
                    strikeVariant: strikeVariant,
                    onStrike: strike(onWeakPoint:)
                )
                if player.mineFace.segmentIndex == 0 { surfaceCanopy }
                ResonanceNodeView(state: resonance, now: resonanceNow) {
                    resonance = ResonanceNodeEngine.claim(resonance, now: Date())
                    feedback.play(.veinFound)
                }
                .position(
                    x: resonance.prefersTrailingEdge
                        ? proxy.size.width - 52
                        : 52,
                    y: max(46, ShaftGeometry.y(for: scene.headDepthMeters, in: scene) - 74)
                )
                depthRuler(width: proxy.size.width)
                regionPlates(width: proxy.size.width)
                ShaftEffectsView(
                    gains: floatingGains,
                    debris: debrisBursts,
                    collapses: groundCollapses,
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
        // Structural growth is readable in the scene; this is the same state in words, so
        // VoiceOver hears the rig the sighted player can count (D-060).
        .accessibilityLabel(
            "\(DeepMineStrings.text(.homeCrewLabel)) \(plant.crew), "
                + "\(DeepMineStrings.text(.gameCart)) \(plant.carts), "
                + "\(DeepMineStrings.text(.gameLamp)) \(plant.serviceLamps)"
        )
        .animation(
            reduceMotion
                ? nil
                : .interactiveSpring(
                    response: 0.34,
                    dampingFraction: 1,
                    blendDuration: 0.08
                ).delay(0.12),
            value: player.mineFace.segmentIndex
        )
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.16),
            value: player.mineFace.brokenFraction
        )
    }

    // MARK: Actions

    private func strike(onWeakPoint: Bool) {
        let struckRegion = player.mineFace.region.rawValue
        struckWeakPoint = onWeakPoint
        let update = MiningLoop.strike(
            hitWeakPoint: onWeakPoint,
            outputMultiplier: ResonanceNodeEngine.outputMultiplier(resonance, at: Date()),
            using: &generator,
            in: &player
        )
        // The variant is chosen from the resolved hit, so a critical reads as the heaviest
        // swing rather than as an ordinary one with a different number over it.
        beginSwing(at: Date().timeIntervalSinceReferenceDate, wasCritical: update.wasCritical)
        lastManualStrikeAt = lastSwingAt
        announce(update, isTap: true, struckRegion: struckRegion)
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
        let struckRegion = player.mineFace.region.rawValue
        let update = MiningLoop.advance(
            seconds: elapsed,
            at: now,
            outputMultiplier: ResonanceNodeEngine.outputMultiplier(resonance, at: now),
            in: &player
        )
        // Damage from every step lands on the rock; only some of those steps are allowed to
        // start a swing. Debris follows the swing, not the step, or the face would shed
        // chips continuously while the pickaxe was nowhere near it.
        if !update.damage.isZero, StrikeTimeline.Cadence.shouldStartAutomaticSwing(
            now: now.timeIntervalSinceReferenceDate,
            lastSwingAt: lastSwingAt,
            lastManualStrikeAt: lastManualStrikeAt
        ) {
            beginSwing(at: now.timeIntervalSinceReferenceDate, wasCritical: false)
            if !update.brokeSomething { showDebris(isLarge: false, densityOverride: 2) }
        }
        if update.brokeSomething {
            announce(update, isTap: false, struckRegion: struckRegion)
        }
    }

    private func beginSwing(at now: TimeInterval, wasCritical: Bool) {
        swingSequence &+= 1
        strikeVariant = StrikeTimeline.Cadence.variant(
            sequence: swingSequence,
            wasCritical: wasCritical
        )
        lastSwingAt = now
        strikeSignal &+= 1
    }

    private func announce(
        _ update: MineFaceUpdate,
        isTap: Bool,
        struckRegion: String
    ) {
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
            showGroundCollapse(region: struckRegion)
            showDebris(isLarge: update.seamsBroken > 0)
            show(FloatingGain(
                text: "+\(DeepMineNumberFormatter.string(big: update.oreGained))",
                kind: .ore,
                offsetX: Double.random(in: -34...34)
            ))
        } else if isTap {
            showDebris(
                isLarge: false,
                densityOverride: update.wasCritical ? 4 : 2
            )
            show(FloatingGain(
                text: DeepMineNumberFormatter.string(big: update.damage),
                kind: update.wasCritical ? .critical : .damage,
                offsetX: Double.random(in: -42...42)
            ))
        }
    }

}
