import DeepMineCore
import SwiftUI

/// Rows, notices and the purchase path for the workbench.
@MainActor
extension EquipmentView {
    func equipmentRow(_ kind: EquipmentKind) -> some View {
        let level = EquipmentEngine.level(of: kind, in: player.equipment)
        let quote = EquipmentEngine.quote(for: kind, in: player)
        let depthLocked = level >= player.unlockedEquipmentLevel
            && level < Balance.maximumEquipmentLevel
        let cost = depthLocked ? nil : quote?.cost
        let maximum = level >= Balance.maximumEquipmentLevel
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
                        status: maximum ? .completed : (recommended ? .attention : .notStarted)
                    ),
                    accessory: AnyView(levelAccessory(kind: kind, level: level, cost: cost))
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
                    // The compounding curve is invisible one level at a time. Naming a
                    // level far above the current one is the only place a player can see
                    // where the ladder actually goes.
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

    func levelAccessory(kind: EquipmentKind, level: Int, cost: Double?) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("Lv. \(level)")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .accessibilityIdentifier("equipment-level-\(kind.rawValue)")
            Button { purchase(kind) } label: {
                Text(buttonTitle(cost: cost))
                    .font(.caption.monospacedDigit().weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(minHeight: 44)
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: highlightedEquipment == kind ? .primary : .secondary))
            .disabled(cost == nil || isLoading || notice == .storageFailure)
            .accessibilityLabel(equipmentButtonLabel(kind: kind, cost: cost))
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

    var maximumPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(maximumEquipment, id: \.self) { kind in
                    Label(
                        "\(DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(kind))) · "
                            + DeepMineStrings.text(.equipmentMaximum),
                        systemImage: DeepMineProgressLabels.equipmentSymbol(kind)
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("equipment-maximum-\(kind.rawValue)")
                }
            }
        }
    }

    var highlightedEquipment: EquipmentKind? {
        (!handoffConsumed ? handoffRecommendation?.equipment : nil) ?? recommendation?.equipment
    }

    /// Ore a milestone drill level would pay for the plan the player last used, so the
    /// number is comparable to what they just earned. Nil once the milestone is behind
    /// them or a projection cannot be made.
    func drillPreview(currentLevel: Int) -> String? {
        let milestones = [10, 20, 30, 40, Balance.maximumEquipmentLevel]
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
            startingDailyMinutes: 0,
            permanentUpgrades: player.permanentUpgrades
        )).ore else { return nil }
        return String(
            format: DeepMineStrings.text(.equipmentPreview),
            milestone,
            DeepMineNumberFormatter.string(ore)
        )
    }

    static let previewCompletionID = UUID(uuidString: "44454550-4D49-4E45-0000-000000000160")!

    var maximumEquipment: [EquipmentKind] {
        EquipmentKind.allCases.filter {
            EquipmentEngine.upgradeCost(
                for: $0,
                currentLevel: EquipmentEngine.level(of: $0, in: player.equipment)
            ) == nil
        }
    }

    func buttonTitle(cost: Double?) -> String {
        guard let cost else { return DeepMineStrings.text(.equipmentMaximum) }
        return "\(DeepMineStrings.text(.actionUpgrade)) · \(DeepMineNumberFormatter.string(cost))"
    }

    func equipmentButtonLabel(kind: EquipmentKind, cost: Double?) -> String {
        let title = DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(kind))
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

    func purchase(_ kind: EquipmentKind, commandID: UUID? = nil) {
        guard let gameStore else { notice = .storageFailure; return }
        let commandID = commandID ?? UUID()
        isLoading = true
        pendingPurchase = (kind, commandID)
        defer { isLoading = false }
        do {
            switch try gameStore.purchaseEquipment(kind, commandID: commandID) {
            case let .purchased(equipment, newLevel, _):
                // Crossing a crew threshold only ever happens here, so this is where the
                // new miner gets named.
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
                // The row already explains why, so no banner is needed.
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
        if let pendingPurchase {
            purchase(pendingPurchase.equipment, commandID: pendingPurchase.commandID)
        } else {
            refresh()
        }
    }
}
