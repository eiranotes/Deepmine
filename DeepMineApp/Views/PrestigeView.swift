import DeepMineCore
import SwiftUI

@MainActor
struct PrestigeView: View {
    private enum Phase { case preview, confirming, allocation }

    let gameStore: GameStore?
    let initialPlayer: PlayerState
    let onPlayerChange: (PlayerState) -> Void
    let onFinish: () -> Void
    @State private var player: PlayerState
    @State private var preview: PrestigePreview?
    @State private var upgrades: [PermanentUpgradePresentation] = []
    @State private var phase: Phase = .preview
    @State private var prestigeCommandID = UUID()
    @State private var upgradeCommandIDs = Dictionary(
        uniqueKeysWithValues: PermanentUpgradeKind.allCases.map { ($0, UUID()) }
    )
    @State private var isApplying = false
    @State private var notice: DeepMineStringKey?

    init(
        gameStore: GameStore?, player: PlayerState,
        onPlayerChange: @escaping (PlayerState) -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.gameStore = gameStore
        initialPlayer = player
        self.onPlayerChange = onPlayerChange
        self.onFinish = onFinish
        _player = State(initialValue: player)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                switch phase {
                case .preview: previewContent
                case .confirming: confirmationContent
                case .allocation: allocationContent
                }
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationPrestige))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("prestige-screen")
        .task { load() }
    }

    @ViewBuilder
    private var previewContent: some View {
        if let preview {
            DeepMineRivetedPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Label(DeepMineStrings.text(.prestigeIntro), systemImage: "arrow.down.to.line.compact")
                        .font(.headline)
                        .accessibilityIdentifier("prestige-preview")
                    DeepMineProgressRail(
                        value: Double(preview.currentRunSegments),
                        total: Double(preview.targetRunSegments),
                        accessibilityLabel: DeepMineStrings.text(.prestigeProgress)
                    )
                    Text("\(preview.currentRunSegments) / \(preview.targetRunSegments) \(DeepMineStrings.text(.prestigeSegments))")
                        .font(.subheadline.monospacedDigit().weight(.heavy))
                    Text(DeepMineStrings.text(preview.isEligible ? .prestigeEligible : .prestigeIneligible))
                        .font(.subheadline)
                        .foregroundStyle(preview.isEligible ? DeepMinePalette.limestone.color : DeepMinePalette.brass.color)
                        .accessibilityIdentifier(preview.isEligible ? "prestige-eligible" : "prestige-ineligible")
                }
            }
            Button { phase = .confirming } label: {
                DeepMineActionLabel(titleKey: .prestigeConfirm, detailKey: .prestigeLossBody, symbol: "arrow.down.to.line.compact")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
            .disabled(!preview.isEligible || gameStore == nil)
            .accessibilityIdentifier("prestige-open-confirmation")
        } else {
            failurePanel
        }
    }

    @ViewBuilder
    private var confirmationContent: some View {
        if let preview {
            DeepMineRivetedPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Label(DeepMineStrings.text(.prestigeLossTitle), systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(DeepMinePalette.brass.color)
                    Text(DeepMineStrings.text(.prestigeLossBody)).font(.subheadline)
                    lossRow(.gameOre, value: DeepMineNumberFormatter.string(preview.losses.ore))
                    // The position goes back to the surface too, which is the loss a
                    // player most needs to see before confirming (D-046).
                    lossRow(.prestigeSegments, value: "\(preview.losses.runSegmentsBroken)")
                    lossRow(.gameDepth, value: DeepMineStrings.text(.prestigeDepthReset))
                    lossRow(.gameDrill, value: "Lv. \(preview.losses.equipment.drill)")
                    lossRow(.gameCart, value: "Lv. \(preview.losses.equipment.cart)")
                    lossRow(.gameLamp, value: "Lv. \(preview.losses.equipment.lamp)")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("prestige-losses")
            DeepMineRivetedPanel {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(DeepMineStrings.text(.prestigeGainTitle)).font(.headline)
                        Spacer()
                        Text("+\(preview.gains.coreShards)")
                            .font(.title3.monospacedDigit().weight(.heavy))
                            .foregroundStyle(DeepMinePalette.brass.color)
                    }
                    Label(
                        "\(DeepMineStrings.text(.gameDepth)) \(preview.gains.keptDepthMeters)m",
                        systemImage: "checkmark.seal"
                    )
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("prestige-kept-depth")
                    Text(DeepMineStrings.text(.prestigeRebuyBody))
                        .font(.caption)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("prestige-rebuy-discount")
                }
            }
            Button { confirmPrestige() } label: {
                DeepMineActionLabel(titleKey: .prestigeConfirm, detailKey: nil, symbol: "checkmark.shield")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
            .disabled(isApplying)
            .accessibilityIdentifier("prestige-confirm")
            Button { phase = .preview } label: {
                DeepMineActionLabel(titleKey: .actionCancel, detailKey: nil, symbol: "xmark")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            .disabled(isApplying)
            .accessibilityIdentifier("prestige-cancel")
            if notice == .prestigeFailed {
                Text(DeepMineStrings.text(.prestigeFailed))
                    .font(.caption)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("prestige-confirmation-error")
            }
        }
    }

    private var allocationContent: some View {
        VStack(spacing: 17) {
            DeepMineRivetedPanel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        DeepMinePixelImage(name: DeepMineArt.coreShard, size: 28)
                            .accessibilityHidden(true)
                        Text(DeepMineStrings.text(.prestigeAllocationTitle))
                            .font(.headline)
                    }
                    Text(DeepMineStrings.text(.prestigeAllocationBody)).font(.subheadline)
                    Text("\(DeepMineStrings.text(.gameCoreShards)) · \(player.resources.coreShards)")
                        .font(.title3.monospacedDigit().weight(.heavy))
                        .foregroundStyle(DeepMinePalette.brass.color)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("prestige-allocation")
            ForEach(upgrades, id: \.upgrade) { upgradePanel($0) }
            if let notice {
                Text(DeepMineStrings.text(notice))
                    .font(.caption)
                    .accessibilityIdentifier(notice == .prestigeUpgradeSuccess
                        ? "prestige-upgrade-success" : "prestige-upgrade-notice")
            }
            Button(action: onFinish) {
                DeepMineActionLabel(titleKey: .actionFinish, detailKey: nil, symbol: "house.fill")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
            .accessibilityIdentifier("prestige-finish")
        }
    }

    private func upgradePanel(_ option: PermanentUpgradePresentation) -> some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    DeepMinePixelImage(
                        name: DeepMineArt.permanentUpgrade(option.upgrade),
                        size: 36
                    )
                    .accessibilityHidden(true)
                    Text(DeepMineStrings.text(DeepMinePrestigeLabels.title(option.upgrade))).font(.headline)
                    Spacer()
                    Text("Lv. \(option.currentLevel)").font(.subheadline.monospacedDigit().weight(.bold))
                }
                Text(DeepMineStrings.text(DeepMinePrestigeLabels.effect(option.upgrade))).font(.subheadline)
                Button { purchase(option.upgrade) } label: {
                    HStack {
                        Text(DeepMineStrings.text(option.isMaximum ? .equipmentMaximum : .actionBuy))
                        Spacer()
                        if let cost = option.nextCost { Text("\(cost) ◆") }
                    }
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                .disabled(option.isMaximum || !option.canAfford || isApplying)
                .accessibilityIdentifier("prestige-upgrade-\(option.upgrade.rawValue)")
            }
        }
    }

    private var failurePanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text(DeepMineStrings.text(.prestigeFailed))
                Button { load() } label: {
                    DeepMineActionLabel(titleKey: .actionRetry, detailKey: nil, symbol: "arrow.clockwise")
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            }
        }
    }

    private func lossRow(_ key: DeepMineStringKey, value: String) -> some View {
        HStack { Text(DeepMineStrings.text(key)); Spacer(); Text(value).monospacedDigit() }
            .font(.subheadline)
    }

    private func confirmPrestige() {
        guard !isApplying, gameStore != nil else { return }
        isApplying = true
        defer { isApplying = false }
        do {
            if let gameStore {
                let result = try gameStore.confirmPrestige(commandID: prestigeCommandID)
                guard case .prestiged = result else {
                    guard result == .duplicate else { return }
                    player = try gameStore.playerState()
                    onPlayerChange(player)
                    upgrades = presentations()
                    phase = .allocation
                    return
                }
                player = try gameStore.playerState()
            } else {
                var updated = player
                guard case .prestiged = PrestigeEngine.prestige(PrestigeCommand(id: prestigeCommandID), in: &updated) else { return }
                player = updated
            }
            onPlayerChange(player)
            upgrades = presentations()
            phase = .allocation
        } catch { notice = .prestigeFailed }
    }

    private func purchase(_ kind: PermanentUpgradeKind) {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }
        do {
            guard let commandID = upgradeCommandIDs[kind] else { return }
            let result: PermanentUpgradePurchaseResult
            if let gameStore {
                result = try gameStore.purchasePermanentUpgrade(kind, commandID: commandID)
                player = try gameStore.playerState()
            } else {
                var updated = player
                result = PrestigeEngine.purchase(
                    PermanentUpgradeCommand(id: commandID, upgrade: kind), in: &updated
                )
                player = updated
            }
            switch result {
            case .purchased, .duplicate:
                notice = .prestigeUpgradeSuccess
                upgradeCommandIDs[kind] = UUID()
            case .insufficientShards, .maximumLevel, .invalidLevel:
                notice = .prestigeInsufficient
            }
            onPlayerChange(player)
            upgrades = presentations()
        } catch { notice = .prestigeFailed }
    }

    private func load() {
        do {
            player = try gameStore?.playerState() ?? initialPlayer
            preview = try gameStore?.prestigePreview() ?? PrestigeEngine.preview(for: player)
            upgrades = presentations()
            if player.prestigeIndex > 0, player.runFocusCredits == 0, player.resources.coreShards > 0 {
                phase = .allocation
            }
        } catch { preview = nil }
    }

    private func presentations() -> [PermanentUpgradePresentation] {
        (try? gameStore?.permanentUpgradePresentations())
            ?? GameStore.permanentUpgradePresentations(for: player)
    }
}
