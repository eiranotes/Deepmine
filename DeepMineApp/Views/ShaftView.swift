import DeepMineCore
import SwiftUI

@MainActor
struct ShaftView: View {
    @Binding var player: PlayerState
    let feedback: GameFeedback
    var onPersist: (PlayerState) -> Void = { _ in }
    var isLive = true

    @State private var generator = SeededGenerator(seed: UInt64.random(in: .min ... .max))
    @State private var struckWeakPoint = false
    @State private var strikeSignal = 0
    @State private var strikeVariant: StrikeVariant = .quick
    @State private var swingSequence = 0
    @State private var lastSwingAt: TimeInterval?
    @State private var lastManualStrikeAt: TimeInterval?
    @State var floatingGains: [FloatingGain] = []
    @State var debrisBursts: [DebrisBurst] = []
    @State var groundCollapses: [GroundCollapseBurst] = []
    @State private var lastTick = Date()
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
                    x: resonance.prefersTrailingEdge ? proxy.size.width - 52 : 52,
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mine-shaft")
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

    private func strike(onWeakPoint: Bool) {
        let struckRegion = player.mineFace.region.rawValue
        struckWeakPoint = onWeakPoint
        let update = MiningLoop.strike(
            hitWeakPoint: onWeakPoint,
            outputMultiplier: ResonanceNodeEngine.outputMultiplier(resonance, at: Date()),
            using: &generator,
            in: &player
        )
        beginSwing(at: Date().timeIntervalSinceReferenceDate, wasCritical: update.wasCritical)
        lastManualStrikeAt = lastSwingAt
        announce(update, isTap: true, struckRegion: struckRegion)
        guard onWeakPoint else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            struckWeakPoint = false
        }
    }

    private func advance(by elapsed: TimeInterval, at now: Date) {
        guard elapsed > 0 else { return }
        let struckRegion = player.mineFace.region.rawValue
        let update = MiningLoop.advance(
            seconds: elapsed,
            at: now,
            outputMultiplier: ResonanceNodeEngine.outputMultiplier(resonance, at: now),
            in: &player
        )
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
            try? MiningStreak.record(
                at: Date(),
                in: &player,
                calendar: .current,
                timeZone: .current,
                incrementSessionCount: false
            )
        }
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
