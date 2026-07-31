import AppIntents
import DeepMineCore
import SwiftUI

enum GameHomeWidgetFamily: Equatable, Sendable {
    case small
    case medium
}

enum GamePassiveSurfaceKinds {
    static let homeWidget = "com.eiraworks.deepmine.home"
    static let safeControl = "com.eiraworks.deepmine.safe-control"
}

enum GameSystemEntryPolicy {
    static func startAction(
        for result: GameSurfaceSnapshotReadResult
    ) -> GameCommandAction? {
        guard case let .fresh(snapshot) = result, snapshot.phase == .waiting else {
            return nil
        }
        return .startSession(length: .minutes25, plan: .safe)
    }
}

struct GameControlValue: Sendable {
    let stateID: String
    let phase: GameSurfacePhase
    let canStart: Bool

    static func make(from result: GameSurfaceSnapshotReadResult) -> Self {
        switch result {
        case .missing:
            Self(stateID: "missing", phase: .waiting, canStart: false)
        case .stale:
            Self(stateID: "stale", phase: .waiting, canStart: false)
        case let .fresh(snapshot):
            Self(
                stateID: snapshot.phase.rawValue,
                phase: snapshot.phase,
                canStart: snapshot.phase == .waiting
            )
        }
    }

    func title(locale: Locale) -> String {
        let key = switch stateID {
        case "waiting": "surface.intent.safe25"
        case "mining": "state.mining"
        case "completed", "vein": "surface.resultReady"
        case "collapsed": "state.collapsed"
        default: "state.stale"
        }
        return GameSurfaceText.localized(key, locale: locale)
    }
}

struct GameControlSurfaceLabel: View {
    let value: GameControlValue
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 7) {
            GameSurfaceMark(phase: value.phase, size: 22)
            Text(value.title(locale: locale))
                .font(.caption.weight(.bold))
                .lineLimit(2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.title(locale: locale))
        .accessibilityIdentifier("control-\(value.stateID)")
    }
}

struct GameHomeWidgetContent: View {
    let result: GameSurfaceSnapshotReadResult
    let family: GameHomeWidgetFamily
    let date: Date
    @Environment(\.locale) private var locale

    private var snapshot: GameSurfaceSnapshot? {
        switch result {
        case let .fresh(snapshot), let .stale(snapshot): snapshot
        case .missing: nil
        }
    }

    private var stateID: String {
        switch result {
        case .missing: "missing"
        case .stale: "stale"
        case let .fresh(snapshot): snapshot.phase.rawValue
        }
    }

    private var phase: GameSurfacePhase {
        if case let .fresh(snapshot) = result { return snapshot.phase }
        return .waiting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            header
            statusRow
            if family == .medium { mediumDetail }
            if showsProgress { progressRail }
            action
        }
        .foregroundStyle(ProbePalette.limestone)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("widget-\(familyID)-\(stateID)")
    }

    private var header: some View {
        HStack {
            Text("DEEPMINE")
                .font(.caption2.monospaced().weight(.black))
            Spacer()
            Text(GameSurfaceText.localized("game.today", locale: locale))
                .font(.caption2.weight(.bold))
                .foregroundStyle(ProbePalette.brass)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 9) {
            GameSurfaceMark(
                phase: phase,
                size: family == .small ? 28 : 36,
                planID: snapshot?.planID ?? "safe",
                veinID: snapshot?.veinID
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.subheadline.weight(.black))
                    .lineLimit(family == .small ? 2 : 1)
                    .minimumScaleFactor(0.84)
                    .accessibilityIdentifier("widget-status-title-\(stateID)")
                Text(statusDetail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ProbePalette.highlight)
                    .lineLimit(family == .small ? 2 : 1)
                    .minimumScaleFactor(0.82)
                    .accessibilityIdentifier("widget-status-detail-\(stateID)")
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var mediumDetail: some View {
        if let snapshot, case .fresh = result {
            Text(mediumDetailText(snapshot))
                .font(.caption2.monospaced().weight(.bold))
                .foregroundStyle(ProbePalette.highlight)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .accessibilityIdentifier("widget-equipment-board-\(stateID)")
        }
    }

    private var progressRail: some View {
        let focused = Double(snapshot?.todayFocusedMinutes ?? 0)
        let goal = Double(max(1, snapshot?.todayGoalMinutes ?? 1))
        return ProgressView(value: min(1, focused / goal))
            .tint(ProbePalette.brass)
            .accessibilityLabel(GameSurfaceText.localized("game.today", locale: locale))
            .accessibilityValue("\(Int(focused)) / \(Int(goal))")
            .accessibilityIdentifier("widget-progress")
    }

    @ViewBuilder
    private var action: some View {
        if case let .fresh(snapshot) = result, snapshot.phase == .waiting {
            widgetButton(
                GameSurfaceText.localized("surface.intent.safe25", locale: locale),
                identifier: "widget-start",
                intent: OpenAndStartSafeMineIntent()
            )
        } else {
            widgetButton(
                GameSurfaceText.localized("action.openApp", locale: locale),
                identifier: "widget-open",
                intent: OpenGameIntent()
            )
        }
    }

    private func widgetButton<Intent: AppIntent>(
        _ title: String,
        identifier: String,
        intent: Intent
    ) -> some View {
        Button(intent: intent) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(ProbePalette.coal)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(ProbePalette.brass, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityIdentifier(identifier)
    }

    private var statusTitle: String {
        guard let snapshot else {
            return recoveryTitle
        }
        if case .stale = result {
            return recoveryTitle
        }
        return family == .small
            ? GameSurfaceText.compactStatus(snapshot, isStale: false, locale: locale)
            : GameSurfaceText.phase(snapshot, locale: locale)
    }

    private var statusDetail: String {
        guard let snapshot else {
            return GameSurfaceText.localized("surface.openToRecover", locale: locale)
        }
        if case .stale = result {
            return GameSurfaceText.localized("surface.openToRecover", locale: locale)
        }
        if snapshot.phase == .mining,
           let start = snapshot.timerStartedAt,
           let end = snapshot.timerEndsAt {
            let remaining = max(0, Int(end - max(start, date.timeIntervalSince1970)))
            return formatted("widget.minutesRemaining", value: Int(ceil(Double(remaining) / 60)))
        }
        if snapshot.phase == .waiting {
            return formatted(
                "widget.todayProgress",
                values: snapshot.todayFocusedMinutes,
                snapshot.todayGoalMinutes
            )
        }
        if snapshot.phase == .vein {
            let vein = GameSurfaceText.vein(snapshot.veinID, locale: locale)
                ?? GameSurfaceText.localized("surface.resultReady", locale: locale)
            return "\(vein) · \(earnedText(snapshot))"
        }
        if snapshot.phase == .completed || snapshot.phase == .collapsed {
            return earnedText(snapshot)
        }
        return GameSurfaceText.localized("surface.openToRecover", locale: locale)
    }

    private func mediumDetailText(_ snapshot: GameSurfaceSnapshot) -> String {
        let plan = GameSurfaceText.plan(snapshot.planID, locale: locale)
        let region = GameSurfaceText.region(snapshot.regionID, locale: locale)
        switch snapshot.phase {
        case .waiting:
            return "\(GameSurfaceText.localized("game.nextPromise", locale: locale)) · \(plan)"
        case .mining:
            return "\(plan) · \(snapshot.depthMeters)m"
        case .completed, .vein, .collapsed:
            return "\(region) · \(snapshot.depthMeters)m"
        }
    }

    private func earnedText(_ snapshot: GameSurfaceSnapshot) -> String {
        "\(GameSurfaceText.localized("surface.earnedOre", locale: locale)) "
            + GameSurfaceText.number(snapshot.earnedOre, locale: locale)
    }

    private func formatted(_ key: String, value: Int) -> String {
        String(
            format: GameSurfaceText.localized(key, locale: locale),
            locale: locale,
            Int64(value)
        )
    }

    private func formatted(_ key: String, values first: Int, _ second: Int) -> String {
        String(
            format: GameSurfaceText.localized(key, locale: locale),
            locale: locale,
            Int64(first),
            Int64(second)
        )
    }

    private var recoveryTitle: String {
        family == .small
            ? GameSurfaceText.localized("widget.compact.recovery", locale: locale)
            : GameSurfaceText.localized("state.stale", locale: locale)
    }

    private var showsProgress: Bool {
        if case .fresh = result { return true }
        return false
    }

    private var familyID: String { family == .small ? "small" : "medium" }
}
