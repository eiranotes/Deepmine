import DeepMineCore
import SwiftUI
@MainActor
extension EquipmentView {
    func equipmentRow(_ kind: EquipmentKind) -> some View {
        let level = EquipmentEngine.level(of: kind, in: player.equipment)
        let quote = EquipmentEngine.quote(for: kind, in: player)
        // With no level ceiling, depth is the only player-facing purchase gate (D-069).
        let depthLocked = level >= player.unlockedEquipmentLevel
        let cost = depthLocked ? nil : quote?.cost
        let recommended = highlightedEquipment == kind
        return DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                DeepMineEquipmentRow(
                    equipment: DeepMineEquipmentDisplay(
                        titleKey: DeepMineProgressLabels.equipmentKey(kind),
                        symbol: DeepMineProgressLabels.equipmentSymbol(kind),
                        assetName: DeepMineArt.equipment(kind, level: level),
                        level: level,
                        detail: DeepMineStrings.text(DeepMineProgressLabels.equipmentEffectKey(kind)),
                        status: recommended ? .attention : .notStarted
                    ),
                    accessory: AnyView(levelAccessory(
                        kind: kind,
                        level: level,
                        cost: cost,
                        depthLocked: depthLocked
                    ))
                )
                if depthLocked {
                    Label(
                        String(
                            format: DeepMineStrings.text(.equipmentDepthLocked),
                            EquipmentEngine.requiredDepth(forLevel: level + 1)
                        ),
                        systemImage: "arrow.down.to.line.compact"
                    )
                    .font(.caption)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("equipment-depth-locked-\(kind.rawValue)")
                } else if quote?.isRemembered == true {
                    Label(DeepMineStrings.text(.equipmentRemembered), systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .accessibilityIdentifier("equipment-remembered-\(kind.rawValue)")
                }
                if kind == .drill, let preview = drillPreview(currentLevel: level) {
                    // A distant milestone makes the otherwise incremental compound curve visible.
                    Text(preview)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("equipment-preview-drill")
                }
            }
        }
        .accessibilityIdentifier("equipment-row-\(kind.rawValue)")
    }

    func levelAccessory(
        kind: EquipmentKind,
        level: Int,
        cost: Double?,
        depthLocked: Bool
    ) -> some View {
        let requiredDepth = depthLocked
            ? EquipmentEngine.requiredDepth(forLevel: level + 1)
            : nil
        return VStack(alignment: .trailing, spacing: 6) {
            Text("Lv. \(level)")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .accessibilityIdentifier("equipment-level-\(kind.rawValue)")
            Button { purchase(kind) } label: {
                Text(buttonTitle(cost: cost, requiredDepth: requiredDepth))
                    .font(.caption.monospacedDigit().weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(minHeight: 44)
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: highlightedEquipment == kind ? .primary : .secondary))
            .disabled(cost == nil || isLoading || notice == .storageFailure)
            .accessibilityLabel(equipmentButtonLabel(
                kind: kind,
                cost: cost,
                requiredDepth: requiredDepth
            ))
            .accessibilityIdentifier("equipment-upgrade-\(kind.rawValue)")
        }
        .frame(minWidth: 118)
    }

    var noticePanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch notice {
            case .success:
                Label(DeepMineStrings.text(.equipmentPurchaseSuccess), systemImage: "checkmark.seal.fill")
                    .accessibilityIdentifier("equipment-notice-success")
            case let .crewGrew(size):
                Label(
                    String(format: DeepMineStrings.text(.returnCrewGrew), size),
                    systemImage: "person.2.fill"
                )
                .accessibilityIdentifier("equipment-notice-crew")
            case let .insufficient(required, available):
                Label(DeepMineStrings.text(.equipmentInsufficientTitle), systemImage: "shippingbox")
                    .accessibilityIdentifier("equipment-notice-insufficient")
                Text("\(DeepMineNumberFormatter.string(available)) / \(DeepMineNumberFormatter.string(required))")
                    .font(.caption.monospacedDigit())
                Text(DeepMineStrings.text(.equipmentInsufficientBody)).font(.caption)
            case .storageFailure, .none:
                EmptyView()
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(DeepMinePalette.brass.color)
        .fixedSize(horizontal: false, vertical: true)
    }

    var recoveryPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label(DeepMineStrings.text(.equipmentStorageTitle), systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("equipment-notice-error")
                Text(DeepMineStrings.text(.equipmentStorageBody))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Button { retry() } label: {
                    DeepMineActionLabel(titleKey: .actionRetry, detailKey: nil, symbol: "arrow.clockwise")
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                .accessibilityIdentifier("equipment-retry")
                .disabled(gameStore == nil)
            }
        }
    }

    var highlightedEquipment: EquipmentKind? {
        (!handoffConsumed ? handoffRecommendation?.equipment : nil) ?? recommendation?.equipment
    }

    /// Ore a milestone drill level would pay for the plan the player last used, so the
    /// number is comparable to what they just earned. Nil once the milestone is behind.
    func drillPreview(currentLevel: Int) -> String? {
        let milestones = [10, 20, 30, 40, 60, 100, 150, 200]
        guard let milestone = milestones.first(where: { $0 > currentLevel + 1 }) else {
            return nil
        }
        var projected = player.equipment
        projected.drill = milestone
        guard let ore = try? RewardCalculator.calculate(RewardInput(
            completionID: Self.previewCompletionID,
            outcome: .completed,
            sessionLength: player.lastSelectedDuration,
            plan: player.lastSelectedPlan,
            verificationGrade: .sealed,
            growthFocusCredits: player.lifetimeFocusCredits,
            streakDays: player.streakDays,
            dailySessionNumber: 1,
            equipment: projected,
            vein: nil,
            resonanceBoostActive: false,
            permanentUpgrades: player.permanentUpgrades
        )).ore else { return nil }
        return String(
            format: DeepMineStrings.text(.equipmentPreview),
            milestone,
            DeepMineNumberFormatter.string(ore)
        )
    }

    static let previewCompletionID = UUID(uuidString: "44454550-4D49-4E45-0000-000000000160")!

    func buttonTitle(cost: Double?, requiredDepth: Int? = nil) -> String {
        if let requiredDepth {
            return String(
                format: DeepMineStrings.text(.equipmentDepthLocked),
                requiredDepth
            )
        }
        guard let cost else { return DeepMineStrings.text(.equipmentMaximum) }
        return "\(DeepMineStrings.text(.actionUpgrade)) · \(DeepMineNumberFormatter.string(cost))"
    }

    func equipmentButtonLabel(
        kind: EquipmentKind,
        cost: Double?,
        requiredDepth: Int? = nil
    ) -> String {
        let title = DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(kind))
        if let requiredDepth {
            return "\(title), " + String(
                format: DeepMineStrings.text(.equipmentDepthLocked),
                requiredDepth
            )
        }
        guard let cost else { return "\(title), \(DeepMineStrings.text(.equipmentMaximum))" }
        return "\(title), \(DeepMineStrings.text(.actionUpgrade)), "
            + "\(DeepMineStrings.text(.equipmentCost)) "
            + "\(DeepMineNumberFormatter.string(cost)) \(DeepMineStrings.text(.gameOre))"
    }

    func refresh() {
        guard let gameStore else {
            notice = .storageFailure
            return
        }
        do {
            player = try gameStore.playerState()
            recommendation = try gameStore.recommendedUpgrade()
            notice = nil
        } catch {
            notice = .storageFailure
        }
    }

    func purchaseRefinement(_ kind: EquipmentKind, commandID: UUID? = nil) {
        guard let gameStore else { notice = .storageFailure; return }
        let commandID = commandID ?? UUID()
        isLoading = true
        pendingRefinement = (kind, commandID)
        defer { isLoading = false }
        do {
            switch try gameStore.purchaseRefinement(kind, commandID: commandID) {
            case .refined, .duplicate:
                player = try gameStore.playerState()
                recommendation = try gameStore.recommendedUpgrade()
                notice = .success
                pendingRefinement = nil
            case let .insufficientOre(required, available):
                notice = .insufficient(required: required, available: available)
                pendingRefinement = nil
            case .locked:
                notice = nil
                pendingRefinement = nil
            }
        } catch {
            notice = .storageFailure
        }
    }

    func purchase(_ kind: EquipmentKind, commandID: UUID? = nil) {
        guard let gameStore else { notice = .storageFailure; return }
        let commandID = commandID ?? UUID()
        isLoading = true
        pendingPurchase = (kind, commandID)
        defer { isLoading = false }
        do {
            switch try gameStore.purchaseEquipment(kind, commandID: commandID) {
            case let .purchased(equipment, newLevel, _):
                notice = equipment == .drill
                    && MineCrew.size(drillLevel: newLevel) > MineCrew.size(drillLevel: newLevel - 1)
                    ? .crewGrew(MineCrew.size(drillLevel: newLevel))
                    : .success
                player = try gameStore.playerState()
                recommendation = try gameStore.recommendedUpgrade()
                if handoffRecommendation?.equipment == kind { handoffConsumed = true }
                pendingPurchase = nil
            case let .insufficientOre(required, available):
                notice = .insufficient(required: required, available: available)
                pendingPurchase = nil
            case .maximumLevel, .depthLocked:
                notice = nil
                pendingPurchase = nil
            case .duplicate:
                player = try gameStore.playerState()
                recommendation = try gameStore.recommendedUpgrade()
                notice = .success
                if handoffRecommendation?.equipment == kind { handoffConsumed = true }
                pendingPurchase = nil
            case .invalidLevel:
                notice = .storageFailure
            }
        } catch {
            notice = .storageFailure
        }
    }

    func retry() {
        notice = nil
        if let pendingRefinement {
            purchaseRefinement(
                pendingRefinement.equipment,
                commandID: pendingRefinement.commandID
            )
        } else if let pendingModification {
            purchaseModification(pendingModification.kind, commandID: pendingModification.commandID)
        } else if let pendingPurchase {
            purchase(pendingPurchase.equipment, commandID: pendingPurchase.commandID)
        } else {
            refresh()
        }
    }
}
