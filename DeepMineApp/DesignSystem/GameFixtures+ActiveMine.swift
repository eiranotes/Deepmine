import DeepMineCore
import Foundation

extension GameFixtures {
    static func sessionPlayer(for name: String) -> PlayerState? {
        let plan: MinePlan
        let duration: SessionLength
        switch name {
        case "preflight-survey": plan = .survey; duration = .minutes50
        case "active-deep": plan = .deep; duration = .minutes25
        case "active-survey": plan = .survey; duration = .minutes25
        case "preflight-sealed", "preflight-open", "preflight-no-list",
             "preflight-pending", "preflight-failure", "active-safe", "active-open",
             "active-collapsed",
             "active-near-end":
            plan = .safe; duration = .minutes25
        default: return nil
        }
        return PlayerState(
            resources: Resources(ore: 1_840, crystals: 4),
            equipment: EquipmentLevels(drill: 4, cart: 3, lamp: 2),
            runFocusCredits: 12,
            lifetimeFocusCredits: 12,
            completedSessionCount: 3,
            streakDays: 7,
            onboardingStage: .complete,
            focusProtectionPermission: .granted,
            endAlertPermission: .granted,
            returnReminderPermission: .granted,
            lastSelectedPlan: plan,
            lastSelectedDuration: duration
        )
    }

    @MainActor
    static func seedActiveSessionIfNeeded(
        named name: String,
        repository: GameRepository
    ) throws {
        guard name.hasPrefix("active-") else { return }
        let player = sessionPlayer(for: name) ?? returningPlayer(completedSessions: 3)
        let now = Date()
        let elapsed: TimeInterval = name == "active-near-end" ? 24 * 60 + 40 : 5 * 60
        let startedAt = now.addingTimeInterval(-elapsed)
        let length = player.lastSelectedDuration
        let open = name == "active-open"
        let collapsed = name == "active-collapsed"
        let clock = SystemGameClock()
        let monotonic = clock.continuousNanoseconds()
        let elapsedNanos = UInt64(elapsed * Balance.nanosecondsPerSecond)
        let session = PersistedGameSession(
            id: UUID(),
            completionID: UUID(),
            originCommandID: nil,
            length: length,
            plan: player.lastSelectedPlan,
            startedAt: startedAt,
            endsAt: startedAt.addingTimeInterval(TimeInterval(length.minutes * 60)),
            clockAnchor: DeepMineCore.ClockAnchor(
                wallClock: startedAt,
                monotonicNanoseconds: monotonic > elapsedNanos ? monotonic - elapsedNanos : 0
            ),
            randomSeed: 12,
            phase: .mining,
            systemsConfigured: true,
            abandonRequested: false,
            abandonSnapshot: nil,
            blockingEnabled: !open,
            shieldMaintained: !open && !collapsed,
            forcedShieldRemoval: collapsed,
            forcedRemovalPending: false,
            openReason: open ? DeepMineStrings.text(.activeOpenReason) : nil,
            alarmDelivery: .none,
            liveActivityID: nil,
            warnings: []
        )
        try repository.saveActiveSession(session, commandID: nil)
    }
}

@MainActor
final class DeterministicSessionSystemCoordinator: SessionSystemCoordinating {
    private let readiness: SessionReadiness

    init(readiness: SessionReadiness) {
        self.readiness = readiness
    }

    func start(
        _ session: PersistedGameSession,
        player: PlayerState,
        at date: Date,
        calendar: Calendar,
        timeZone: TimeZone
    ) async -> SessionSystemStartResult {
        try? await Task.sleep(for: .seconds(1))
        if readiness == .sealed || readiness == .pending {
            return SessionSystemStartResult(
                shield: .sealed,
                alarmDelivery: .localNotification,
                liveActivityID: "ui-test",
                warnings: []
            )
        }
        return SessionSystemStartResult(
            shield: .open(reason: DeepMineStrings.text(readiness.titleKey)),
            alarmDelivery: .none,
            liveActivityID: nil,
            warnings: []
        )
    }

    func finish(
        _ session: PersistedGameSession,
        completedSnapshot: GameSurfaceSnapshot?
    ) async -> [String] { [] }
    func publishWaiting(_ snapshot: GameSurfaceSnapshot) async -> Bool { true }
    func recoverExpiredShield(at date: Date) async -> [String] { [] }
    func shieldIntegrity(for session: PersistedGameSession) -> SessionShieldIntegrity {
        session.shieldMaintained ? .maintained : .unavailable
    }
    func forceRemoveShield(for session: PersistedGameSession) async -> Bool { true }
}
