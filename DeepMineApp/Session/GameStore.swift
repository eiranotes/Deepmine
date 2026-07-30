import DeepMineCore
import Foundation
@MainActor
final class GameStore {
    let repository: any GameSessionRepository
    let coordinator: any SessionSystemCoordinating
    let clock: AnyGameClock
    let calendar: Calendar
    let timeZone: TimeZone
    var activeSession: PersistedGameSession?
    var returnReport: GameReturnReport?
    var visibleReason: String?
    var resumeTask: Task<Void, Error>?
    init(
        repository: any GameSessionRepository,
        coordinator: any SessionSystemCoordinating,
        clock: any DeepMineCore.ClockSource = SystemGameClock(),
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) {
        self.repository = repository
        self.coordinator = coordinator
        self.clock = AnyGameClock(clock)
        self.calendar = calendar
        self.timeZone = timeZone
    }
    func start(length: SessionLength, plan: MinePlan) async throws {
        try prepare(length: length, plan: plan, commandID: nil)
        try await resume()
    }
    func acceptQueuedCommand(_ command: GameCommand) throws -> Bool {
        switch command.action {
        case let .startSession(length, plan):
            let persisted = try repository.loadActiveSession()
            if let matching = [activeSession, persisted].compactMap({ $0 })
                .first(where: { $0.originCommandID == command.id }) {
                activeSession = matching
                return true
            }
            guard activeSession == nil, persisted == nil else { return false }
            try prepare(length: length, plan: plan, commandID: command.id)
            return true
        case .abandonSession:
            let persisted = try repository.loadActiveSession()
            guard var session = activeSession ?? persisted else {
                try repository.markCommandApplied(command.id)
                return true
            }
            checkpointAbandonment(in: &session)
            try repository.saveActiveSession(session, commandID: command.id)
            activeSession = session
            return true
        case .upgradeEquipment, .purchasePermanentUpgrade, .prestige, .open:
            return false
        }
    }
    func performResume() async throws {
        returnReport = try repository.loadReturnReport()
        let recoveryWarnings = await coordinator.recoverExpiredShield(at: clock.wallNow())
        guard var session = try repository.loadActiveSession() else {
            activeSession = nil
            visibleReason = recoveryWarnings.first
            if returnReport == nil {
                do {
                    let published = try await publishWaitingSurface()
                    if !published {
                        visibleReason = visibleReason
                            ?? "광산 현황판을 새로고침하지 못했습니다."
                    }
                } catch {
                    visibleReason = visibleReason
                        ?? "광산 현황판을 새로고침하지 못했습니다."
                }
            }
            return
        }
        activeSession = session
        if session.forcedRemovalPending {
            let succeeded = await coordinator.forceRemoveShield(for: session)
            let message = session.recordForcedRemovalResult(succeeded: succeeded)
            try repository.saveActiveSession(session, commandID: nil)
            activeSession = session
            visibleReason = message
        }
        if session.phase == .completed || session.phase == .abandoned {
            guard let report = returnReport else { throw GameStoreError.noActiveSession }
            _ = try await finishCleanup(session: session, report: report)
        } else if session.abandonRequested {
            _ = try await finalize(session: session, completed: false)
        } else if session.endsAt <= clock.wallNow() {
            _ = try await finalize(session: session, completed: true)
        } else if session.phase == .preparing || !session.systemsConfigured {
            if session.phase == .preparing {
                session.phase = .mining
                try repository.saveActiveSession(session, commandID: nil)
                activeSession = session
            }
            let result = await coordinator.start(
                session,
                player: try repository.loadPlayer(),
                at: clock.wallNow(),
                calendar: calendar,
                timeZone: timeZone
            )
            apply(result, to: &session)
            do {
                try repository.saveActiveSession(session, commandID: nil)
            } catch {
                _ = await coordinator.finish(session, completedSnapshot: nil)
                session.phase = .preparing
                session.systemsConfigured = false
                session.blockingEnabled = false
                session.shieldMaintained = false
                session.liveActivityID = nil
                session.alarmDelivery = .none
                try? repository.saveActiveSession(session, commandID: nil)
                activeSession = session
                throw error
            }
            activeSession = session
            visibleReason = session.openReason ?? session.warnings.first
        } else {
            visibleReason = session.openReason ?? session.warnings.first
                ?? recoveryWarnings.first ?? visibleReason
        }
    }
    @discardableResult
    func completeIfNeeded() async throws -> GameReturnReport? {
        let persisted = try repository.loadActiveSession()
        guard let session = activeSession ?? persisted else { return nil }
        guard session.endsAt <= clock.wallNow() else { return nil }
        return try await finalize(session: session, completed: true)
    }
    func abandon() async throws -> GameReturnReport {
        let persisted = try repository.loadActiveSession()
        guard var session = activeSession ?? persisted else {
            throw GameStoreError.noActiveSession
        }
        if !session.abandonRequested {
            checkpointAbandonment(in: &session)
            try repository.saveActiveSession(session, commandID: nil)
            activeSession = session
        }
        return try await finalize(session: session, completed: false)
    }
    func recordForcedShieldRemoval() async throws {
        let persisted = try repository.loadActiveSession()
        guard var session = activeSession ?? persisted else {
            throw GameStoreError.noActiveSession
        }
        session.forcedShieldRemoval = true
        session.shieldMaintained = false
        session.forcedRemovalPending = true
        try repository.saveActiveSession(session, commandID: nil)
        activeSession = session
        visibleReason = "집중 차단 해제를 요청했습니다."
        let succeeded = await coordinator.forceRemoveShield(for: session)
        visibleReason = session.recordForcedRemovalResult(succeeded: succeeded)
        try repository.saveActiveSession(session, commandID: nil)
        activeSession = session
    }
    func diagnosticSnapshot() -> GameStoreDiagnostic {
        GameStoreDiagnostic(
            activeSession: activeSession,
            returnReport: returnReport,
            visibleReason: visibleReason
        )
    }
    private func prepare(length: SessionLength, plan: MinePlan, commandID: UUID?) throws {
        guard activeSession == nil, try repository.loadActiveSession() == nil else {
            throw GameStoreError.sessionAlreadyActive
        }
        let now = clock.wallNow()
        let completionID = UUID()
        let session = PersistedGameSession(
            id: UUID(), completionID: completionID, originCommandID: commandID,
            length: length, plan: plan, startedAt: now,
            endsAt: now.addingTimeInterval(TimeInterval(length.minutes * 60)),
            clockAnchor: ClockIntegrityChecker.start(source: clock),
            randomSeed: gameSessionSeed(for: completionID), phase: .preparing,
            systemsConfigured: false, abandonRequested: false, abandonSnapshot: nil,
            blockingEnabled: false, shieldMaintained: false,
            forcedShieldRemoval: false, forcedRemovalPending: false,
            openReason: nil, alarmDelivery: .none,
            liveActivityID: nil, warnings: []
        )
        try repository.saveActiveSession(session, commandID: commandID)
        activeSession = session
    }
    private func apply(_ result: SessionSystemStartResult, to session: inout PersistedGameSession) {
        session.systemsConfigured = true
        session.openReason = nil
        session.blockingEnabled = result.shield == .sealed
        session.shieldMaintained = result.shield == .sealed
        var warnings = result.warnings
        if case let .open(reason) = result.shield {
            session.openReason = reason
            if !warnings.contains(reason) { warnings.append(reason) }
        }
        session.alarmDelivery = result.alarmDelivery
        session.liveActivityID = result.liveActivityID
        session.warnings = Array(warnings.prefix(8))
    }
    private func checkpointAbandonment(in session: inout PersistedGameSession) {
        guard session.abandonSnapshot == nil else {
            session.abandonRequested = true
            return
        }
        let requestedAt = clock.wallNow()
        let observation = ClockIntegrityChecker.finish(anchor: session.clockAnchor, source: clock)
        session.abandonRequested = true
        session.abandonSnapshot = AbandonSnapshot(
            requestedAt: requestedAt,
            elapsedMinutes: min(
                session.length.minutes,
                max(0, Int(observation.acceptedElapsed / 60))
            ),
            clockAssessment: observation.assessment,
            verificationGrade: verificationGrade(
                for: session, observation: observation, at: requestedAt
            )
        )
    }
}
