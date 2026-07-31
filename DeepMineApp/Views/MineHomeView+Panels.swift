import DeepMineCore
import SwiftUI

/// The panels inside the mine control scene.
extension MineHomeView {
    var streakLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundStyle(DeepMinePalette.brass.color)
            Text("\(DeepMineStrings.text(.homeStreakActive)) \(player.streakDays)\(DeepMineStrings.text(.gameDays))")
                .font(.caption.weight(.semibold))
            Text("·")
                .font(.caption)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.5))
            Text(DeepMineStrings.text(
                hasRestDayAvailable ? .homeRestDayAvailable : .homeRestDayUsed
            ))
            .font(.caption2)
            .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.64))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("mine-home-streak")
    }

    var mineScene: some View {
        ZStack(alignment: .bottomLeading) {
            Image(DeepMineArt.theme(player.selectedTheme))
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .frame(height: 142)
                .clipped()
                .opacity(0.72)
                .accessibilityHidden(true)
            // The pixel art is busy and goes red-monochrome in StandBy Night Mode, so
            // the readable numbers get their own ground instead of sitting on top of it.
            LinearGradient(
                colors: [DeepMinePalette.coal.color.opacity(0), DeepMinePalette.coal.color.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 88)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            MineDecorationScene(decorations: player.unlockedDecorations)
                .padding(.trailing, 12)
                .padding(.bottom, 8)
            MinerCrewScene(crewSize: MineCrew.size(for: player))
                .padding(.leading, 12)
                .padding(.bottom, 10)
            HStack(alignment: .bottom, spacing: 12) {
                Spacer().frame(width: 68)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(player.depthMeters)m")
                        .font(.title2.monospacedDigit().weight(.heavy))
                        .foregroundStyle(DeepMinePalette.brass.color)
                    HStack(spacing: 10) {
                        resourceAmount(
                            name: DeepMineArt.crystal,
                            value: player.resources.crystals
                        )
                        resourceAmount(
                            name: DeepMineArt.coreShard,
                            value: player.resources.coreShards
                        )
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
        }
        .background(DeepMinePalette.coal.color)
        .clipShape(RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DeepMineMetrics.buttonCornerRadius)
                .stroke(DeepMinePalette.limestone.color.opacity(0.28))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(DeepMineStrings.text(.gameDepth)) \(player.depthMeters)m, \(depthResources)"
        )
    }

    var todayProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DeepMineStrings.text(.gameDailyGoal))
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(todayMinutes) / \(player.dailyGoalMinutes) \(DeepMineStrings.text(.gameMinutes))")
                    .font(.caption.monospacedDigit().weight(.semibold))
            }
            DeepMineProgressRail(
                value: Double(todayMinutes),
                total: Double(player.dailyGoalMinutes),
                accessibilityLabel: DeepMineStrings.text(.gameDailyGoal)
            )
        }
    }

    var planSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DeepMineStrings.text(.gamePlan)).font(.subheadline.weight(.bold))
            HStack(spacing: 8) {
                planButton(.safe, title: .gameSafePlan)
                planButton(.deep, title: .gameDeepPlan)
                planButton(.survey, title: .gameSurveyPlan)
            }
            // A plan is a strategy choice, not a duration. Without the numbers the
            // survey shaft reads as strictly worse than the safe one.
            Text(DeepMineStrings.text(planDetailKey))
                .font(.caption)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("mine-home-plan-detail")
            if !player.isDeepMiningUnlocked {
                Label(DeepMineStrings.text(.homeDeepLock), systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("mine-home-deep-lock-reason")
            }
        }
    }

    var durationSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DeepMineStrings.text(.gameDuration)).font(.subheadline.weight(.bold))
            HStack(spacing: 8) {
                ForEach(SessionLength.allCases, id: \.self) { length in
                    choiceButton(
                        title: "\(length.minutes)",
                        selected: player.lastSelectedDuration == length,
                        identifier: "mine-home-duration-\(length.minutes)"
                    ) { onSelectDuration(length) }
                }
            }
        }
    }

    /// Three reachable goals instead of one sentence. The single-promise rule keeps the
    /// screen to one brass action; it should not hide the horizon that makes the next
    /// weeks worth showing up for.
    var nextPromise: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Image(systemName: "signpost.right.and.left.fill")
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .frame(width: 28)
                Text(DeepMineStrings.text(.gameNextPromise))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
            }
            if nextSteps.isEmpty {
                Text(nextPromiseText)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("mine-home-next-promise")
            } else {
                ForEach(nextSteps, id: \.kind) { stepRow($0) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepRow(_ step: NextStep) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(stepTitle(step))
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 8)
                Text(stepDetail(step))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.7))
            }
            DeepMineProgressRail(
                value: Double(step.current),
                total: Double(max(1, step.target)),
                accessibilityLabel: stepTitle(step)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("mine-home-step-\(step.kind.rawValue)")
    }

    var equipmentSummary: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                equipment(.gameDrill, kind: .drill, level: player.equipment.drill)
                equipment(.gameCart, kind: .cart, level: player.equipment.cart)
                equipment(.gameLamp, kind: .lamp, level: player.equipment.lamp)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(DeepMineStrings.text(.homeEquipmentSummary))
            upgradeAffordance
        }
    }

    /// Ore is only satisfying if it can be spent where it is shown. Without this the
    /// only economic decision sits a navigation level away from the number.
    @ViewBuilder
    var upgradeAffordance: some View {
        if let recommendation {
            Button { onUpgrade(recommendation.equipment) } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(DeepMinePalette.brass.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(equipmentTitle(recommendation.equipment)) Lv. \(recommendation.currentLevel) → \(recommendation.nextLevel)")
                            .font(.subheadline.weight(.bold))
                        Text(DeepMineStrings.text(
                            recommendation.isRemembered ? .equipmentRemembered : .homeUpgradeReady
                        ))
                        .font(.caption2)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.7))
                    }
                    Spacer(minLength: 0)
                    Text(DeepMineNumberFormatter.string(recommendation.cost))
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            .accessibilityIdentifier("mine-home-upgrade")
        } else {
            Label(
                DeepMineStrings.text(
                    isEquipmentDepthLocked ? .homeUpgradeDepthLocked : .homeUpgradeSaving
                ),
                systemImage: isEquipmentDepthLocked ? "arrow.down.to.line.compact" : "hourglass"
            )
            .font(.caption)
            .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.68))
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("mine-home-upgrade-unavailable")
        }
    }

    var startButton: some View {
        Button(action: onStart) {
            DeepMineActionLabel(titleKey: .actionStart, detailKey: .homeStartDetail, symbol: "hammer.fill")
        }
        .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
        .accessibilityIdentifier("mine-home-start")
    }

    func planButton(_ plan: MinePlan, title: DeepMineStringKey) -> some View {
        choiceButton(
            title: DeepMineStrings.text(title),
            selected: player.lastSelectedPlan == plan,
            identifier: "mine-home-plan-\(plan.rawValue)",
            enabled: plan != .deep || player.isDeepMiningUnlocked
        ) { onSelectPlan(plan) }
    }

    func choiceButton(
        title: String,
        selected: Bool,
        identifier: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(selected ? DeepMinePalette.brass.color : DeepMinePalette.limestone.color)
                .background(
                    DeepMinePalette.coal.color,
                    in: RoundedRectangle(cornerRadius: DeepMineMetrics.badgeCornerRadius)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: DeepMineMetrics.badgeCornerRadius)
                        .stroke(
                            (selected ? DeepMinePalette.brass : DeepMinePalette.limestone).color
                                .opacity(enabled ? (selected ? 1 : 0.34) : 0.16),
                            lineWidth: selected ? 2 : 1
                        )
                }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.48)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    func equipment(_ key: DeepMineStringKey, kind: EquipmentKind, level: Int) -> some View {
        VStack(spacing: 4) {
            DeepMinePixelImage(name: DeepMineArt.equipment(kind, level: level), size: 30)
                .accessibilityHidden(true)
            Text(DeepMineStrings.text(key)).font(.caption2.weight(.bold)).lineLimit(1)
            Text("Lv. \(level)").font(.caption.monospacedDigit())
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(DeepMinePalette.shale.color, in: RoundedRectangle(cornerRadius: 6))
        .overlay { RoundedRectangle(cornerRadius: 6).stroke(DeepMinePalette.limestone.color.opacity(0.24)) }
        .accessibilityElement(children: .combine)
    }

    func resourceAmount(name: String, value: Int) -> some View {
        HStack(spacing: 4) {
            DeepMinePixelImage(name: name, size: 16)
                .accessibilityHidden(true)
            Text("\(value)")
                .font(.caption.monospacedDigit().weight(.semibold))
        }
    }
}
