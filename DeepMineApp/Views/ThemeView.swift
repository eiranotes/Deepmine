import DeepMineCore
import SwiftUI

@MainActor
struct ThemeView: View {
    let gameStore: GameStore?
    let player: PlayerState
    let onPlayerChange: (PlayerState) -> Void
    @State private var options: [ThemePresentation] = []
    @State private var notice: DeepMineStringKey?
    @State private var failed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                DeepMineRivetedPanel {
                    Text(DeepMineStrings.text(.themeIntro))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if failed { failurePanel }
                ForEach(options, id: \.theme) { option in themePanel(option) }
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationThemes))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("theme-screen")
        .task { load() }
    }

    private func themePanel(_ option: ThemePresentation) -> some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                themePattern(option.theme)
                HStack {
                    Text(DeepMineStrings.text(titleKey(option.theme)))
                        .font(.headline)
                    Spacer()
                    if option.isSelected {
                        DeepMineStatusMarker(status: .completed)
                            .accessibilityIdentifier("theme-selected-\(option.theme.rawValue)")
                    }
                }
                if option.isUnlocked {
                    Button { select(option.theme) } label: {
                        DeepMineActionLabel(
                            titleKey: option.isSelected ? .stateSelected : .actionSelect,
                            detailKey: nil,
                            symbol: option.isSelected ? "checkmark.seal.fill" : "paintbrush"
                        )
                    }
                    .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                    .disabled(option.isSelected || gameStore == nil)
                    .accessibilityIdentifier("theme-select-\(option.theme.rawValue)")
                } else {
                    Text("\(DeepMineStrings.text(.themeUnlockDepth)) \(option.unlockDepthMeters)m")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .accessibilityIdentifier("theme-locked-\(option.theme.rawValue)")
                    Button {} label: {
                        DeepMineActionLabel(titleKey: .stateLocked, detailKey: nil, symbol: "lock.fill")
                    }
                    .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                    .disabled(true)
                    .accessibilityIdentifier("theme-select-\(option.theme.rawValue)")
                }
                if let notice, option.isSelected {
                    Text(DeepMineStrings.text(notice))
                        .font(.caption)
                        .accessibilityIdentifier("theme-selection-notice")
                }
            }
        }
    }

    private func themePattern(_ theme: MineTheme) -> some View {
        let symbols: [String] = switch theme {
        case .entry: ["circle", "line.diagonal"]
        case .crystal: ["diamond.fill", "sparkle"]
        case .ruins: ["square.split.diagonal.2x2", "building.columns.fill"]
        case .abyss: ["circle.hexagongrid.fill", "arrow.down"]
        }
        return HStack(spacing: 18) {
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: symbols[index % symbols.count])
                    .foregroundStyle(index.isMultiple(of: 2)
                        ? DeepMinePalette.brass.color
                        : DeepMinePalette.limestone.color)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .background(DeepMinePalette.coal.color)
        .accessibilityHidden(true)
    }

    private var failurePanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text(DeepMineStrings.text(.themeSaveFailed))
                Button { load() } label: {
                    DeepMineActionLabel(titleKey: .actionRetry, detailKey: nil, symbol: "arrow.clockwise")
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            }
        }
        .accessibilityIdentifier("theme-error")
    }

    private func select(_ theme: MineTheme) {
        guard let gameStore else { failed = true; return }
        do {
            guard try gameStore.selectTheme(theme) != .locked else { return }
            let updated = try gameStore.playerState()
            onPlayerChange(updated)
            options = try gameStore.themePresentations()
            notice = .themeSelectedNotice
            failed = false
        } catch {
            failed = true
        }
    }

    private func load() {
        do {
            options = try gameStore?.themePresentations()
                ?? GameStore.themePresentations(for: player)
            failed = false
        } catch {
            failed = true
        }
    }

    private func titleKey(_ theme: MineTheme) -> DeepMineStringKey {
        switch theme {
        case .entry: .regionEntry
        case .crystal: .regionCrystal
        case .ruins: .regionRuins
        case .abyss: .regionAbyss
        }
    }
}
