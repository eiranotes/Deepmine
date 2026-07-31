import DeepMineCore
import Foundation
import SwiftUI

@MainActor
struct ProgressNavigationContext {
    let gameStore: GameStore?
    let player: PlayerState
    let referenceDate: Date
    let calendar: Calendar
    let timeZone: TimeZone
    let onPlayerChange: (PlayerState) -> Void

    @ViewBuilder
    func destination(for route: GameRoute) -> some View {
        switch route {
        case .equipment:
            EquipmentView(
                gameStore: gameStore,
                player: player,
                onPlayerChange: onPlayerChange
            )
        case .statistics:
            StatisticsView(
                gameStore: gameStore,
                player: player,
                referenceDate: referenceDate,
                calendar: calendar,
                timeZone: timeZone
            )
        case .achievements:
            AchievementsView(player: player)
        default:
            EmptyView()
        }
    }
}

struct ProgressNavigationPanel: View {
    let context: ProgressNavigationContext
    var body: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(DeepMineStrings.text(.progressHomeTitle))
                        .font(.headline)
                    Text(DeepMineStrings.text(.progressHomeBody))
                        .font(.caption)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                ledgerButton(
                    title: .navigationEquipment,
                    symbol: "wrench.and.screwdriver",
                    identifier: "mine-home-equipment",
                    route: .equipment(nil)
                )
                ledgerButton(
                    title: .navigationStatistics,
                    symbol: "list.number",
                    identifier: "mine-home-statistics",
                    route: .statistics
                )
                ledgerButton(
                    title: .navigationAchievements,
                    symbol: "rosette",
                    identifier: "mine-home-achievements",
                    route: .achievements
                )
            }
        }
    }

    private func ledgerButton(
        title: DeepMineStringKey,
        symbol: String,
        identifier: String,
        route: GameRoute
    ) -> some View {
        NavigationLink {
            context.destination(for: route)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol).frame(width: 24)
                Text(DeepMineStrings.text(title))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(DeepMinePalette.limestone.color)
            .padding(.horizontal, 12)
            .background(
                DeepMinePalette.coal.color,
                in: RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                    .stroke(DeepMinePalette.limestone.color.opacity(0.28))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
