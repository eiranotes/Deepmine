import DeepMineCore
import SwiftUI
@MainActor
extension EquipmentView {
    func equipmentRow(_ kind: EquipmentKind) -> some View {
        let level = EquipmentEngine.level(of: kind, in: player.equipment)
        let quote = EquipmentEngine.quote(for: kind, in: player)
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
                        kind: kind, level: level, cost: cost, depthLocked: depthLocked
                    ))
                )
                if depthLocked {
                    Label(
                        String(format: DeepMineStrings.text(.equipmentDepthLocked),
                               EquipmentEngine.requiredDepth(forLevel: level + 1)),
                        systemImage: "arrow.down.to.line.compact"
                    )
                    .font(.caption).foregroundStyle(DeepMinePalette.brass.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("equipment-depth-locked-\(kind.rawValue)")
                } else {
                    bulkControls(kind, hasRememberedLevels: quote?.isRemembered == true)
                    if quote?.isRemembered == true {
                        Label(DeepMineStrings.text(.equipmentRemembered),
                              systemImage: "clock.arrow.circlepath")
                            .font(.caption).foregroundStyle(DeepMinePalette.brass.color)
                            .accessibilityIdentifier("equipment-remembered-\(kind.rawValue)")
                    }
                }
            }
        }
        .accessibilityIdentifier("equipment-row-\(kind.rawValue)")
    }

    func levelAccessory(kind: EquipmentKind, level: Int, cost: Double?, depthLocked: Bool) -> some View {
        let requiredDepth = depthLocked ? EquipmentEngine.requiredDepth(forLevel: level + 1) : nil
        return VStack(alignment: .trailing, spacing: 6) {
            Text("Lv. \(level)").font(.subheadline.monospacedDigit().weight(.bold))
                .accessibilityIdentifier("equipment-level-\(kind.rawValue)")
            Button { purchase(kind) } label: {
                Text(buttonTitle(cost: cost, requiredDepth: requiredDepth))
                    .font(.caption.monospacedDigit().weight(.bold)).lineLimit(2)
                    .minimumScaleFactor(0.78).frame(minHeight: 44)
            }
            .buttonStyle(DeepMineMetalButtonStyle(
                role: highlightedEquipment == kind ? .primary : .secondary
            ))
            .disabled(cost == nil || isLoading || notice == .storageFailure)
            .accessibilityLabel(equipmentButtonLabel(
                kind: kind, cost: cost, requiredDepth: requiredDepth
            ))
            .accessibilityIdentifier("equipment-upgrade-\(kind.rawValue)")
        }
        .frame(minWidth: 118)
    }

    func bulkControls(_ kind: EquipmentKind, hasRememberedLevels: Bool) -> some View {
        HStack(spacing: 7) {
            bulkButton("×10", kind: kind, maximum: 10)
            bulkButton("×100", kind: kind, maximum: 100)
            bulkButton("MAX", kind: kind, maximum: nil)
            if hasRememberedLevels {
                Button { purchaseBulk(kind, remembered: true) } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                .disabled(isLoading || notice == .storageFailure)
                .accessibilityLabel(DeepMineStrings.text(.equipmentRemembered))
                .accessibilityIdentifier("equipment-rebuild-\(kind.rawValue)")
            }
        }
        .accessibilityIdentifier("equipment-bulk-\(kind.rawValue)")
    }

    func bulkButton(_ title: String, kind: EquipmentKind, maximum: Int?) -> some View {
        Button { purchaseBulk(kind, maximum: maximum) } label: {
            Text(title).font(.caption2.monospacedDigit().weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
        .disabled(isLoading || notice == .storageFailure)
        .accessibilityIdentifier("equipment-bulk-\(kind.rawValue)-\(title)")
    }

    var noticePanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch notice {
            case .success:
                Label(DeepMineStrings.text(.equipmentPurchaseSuccess), systemImage: "checkmark.seal.fill")
                    .accessibilityIdentifier("equipment-notice-success")
            case let .crewGrew(size):
                Label(String(format: DeepMineStrings.text(.returnCrewGrew), size),
                      systemImage: "person.2.fill")
                    .accessibilityIdentifier("equipment-notice-crew")
            case let .insufficient(required, available):
                Label(DeepMineStrings.text(.equipmentInsufficientTitle), systemImage: "shippingbox")
                    .accessibilityIdentifier("equipment-notice-insufficient")
                Text("\(DeepMineNumberFormatter.string(available)) / \(DeepMineNumberFormatter.string(required))")
                    .font(.caption.monospacedDigit())
                Text(DeepMineStrings.text(.equipmentInsufficientBody)).font(.caption)
            case .storageFailure, .none: EmptyView()
            }
        }
        .font(.caption.weight(.semibold)).foregroundStyle(DeepMinePalette.brass.color)
        .fixedSize(horizontal: false, vertical: true)
    }

    var recoveryPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label(DeepMineStrings.text(.equipmentStorageTitle), systemImage: "exclamationmark.triangle")
                    .font(.headline).foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("equipment-notice-error")
                Text(DeepMineStrings.text(.equipmentStorageBody)).font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Button { retry() } label: {
                    DeepMineActionLabel(titleKey: .actionRetry, detailKey: nil, symbol: "arrow.clockwise")
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                .accessibilityIdentifier("equipment-retry").disabled(gameStore == nil)
            }
        }
    }

    var highlightedEquipment: EquipmentKind? {
        (!handoffConsumed ? handoffRecommendation?.equipment : nil) ?? recommendation?.equipment
    }

    func buttonTitle(cost: Double?, requiredDepth: Int? = nil) -> String {
        if let requiredDepth {
            return String(format: DeepMineStrings.text(.equipmentDepthLocked), requiredDepth)
        }
        guard let cost else { return DeepMineStrings.text(.equipmentMaximum) }
        return "\(DeepMineStrings.text(.actionUpgrade)) · \(DeepMineNumberFormatter.string(cost))"
    }

    func equipmentButtonLabel(kind: EquipmentKind, cost: Double?, requiredDepth: Int? = nil) -> String {
        let title = DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(kind))
        if let requiredDepth {
            return "\(title), " + String(format: DeepMineStrings.text(.equipmentDepthLocked), requiredDepth)
        }
        guard let cost else { return "\(title), \(DeepMineStrings.text(.equipmentMaximum))" }
        return "\(title), \(DeepMineStrings.text(.actionUpgrade)), "
            + "\(DeepMineStrings.text(.equipmentCost)) "
            + "\(DeepMineNumberFormatter.string(cost)) \(DeepMineStrings.text(.gameOre))"
    }

    func refresh() {
        guard let gameStore else { notice = .storageFailure; return }
        do {
            player = try gameStore.playerState()
            recommendation = try gameStore.recommendedUpgrade()
            notice = nil
        } catch { notice = .storageFailure }
    }

    func purchaseBulk(_ kind: EquipmentKind, maximum: Int? = nil, remembered: Bool = false) {
        guard let gameStore else { notice = .storageFailure; return }
        isLoading = true
        defer { isLoading = false }
        do {
            switch try gameStore.purchaseEquipmentBulk(
                kind, maximumPurchases: maximum, stopAtRememberedLevel: remembered
            ) {
            case .purchased, .duplicate:
                player = try gameStore.playerState()
                recommendation = try gameStore.recommendedUpgrade()
                notice = .success
            case .nothingAffordable, .depthLocked: notice = nil
            case .invalidLevel: notice = .storageFailure
            }
        } catch { notice = .storageFailure }
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
                notice = .success; pendingRefinement = nil
            case let .insufficientOre(required, available):
                notice = .insufficient(required: required, available: available)
                pendingRefinement = nil
            case .locked: notice = nil; pendingRefinement = nil
            }
        } catch { notice = .storageFailure }
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
                    ? .crewGrew(MineCrew.size(drillLevel: newLevel)) : .success
                player = try gameStore.playerState()
                recommendation = try gameStore.recommendedUpgrade()
                if handoffRecommendation?.equipment == kind { handoffConsumed = true }
                pendingPurchase = nil
            case let .insufficientOre(required, available):
                notice = .insufficient(required: required, available: available)
                pendingPurchase = nil
            case .maximumLevel, .depthLocked: notice = nil; pendingPurchase = nil
            case .duplicate:
                refresh(); notice = .success
                if handoffRecommendation?.equipment == kind { handoffConsumed = true }
                pendingPurchase = nil
            case .invalidLevel: notice = .storageFailure
            }
        } catch { notice = .storageFailure }
    }

    func retry() {
        notice = nil
        if let value = pendingRefinement { purchaseRefinement(value.equipment, commandID: value.commandID) }
        else if let value = pendingModification { purchaseModification(value.kind, commandID: value.commandID) }
        else if let value = pendingPurchase { purchase(value.equipment, commandID: value.commandID) }
        else { refresh() }
    }
}
