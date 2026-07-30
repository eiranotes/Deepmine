import DeepMineCore
import Foundation

@MainActor
extension GameStore {
    func verificationGrade(
        for session: PersistedGameSession,
        observation: DeepMineCore.ClockObservation,
        at date: Date
    ) -> VerificationGrade {
        let removedEarly = session.blockingEnabled
            && coordinator.shieldIntegrity(for: session) == .removed
            && date < session.endsAt
        var grade = VerificationGrade.resolve(
            blockingEnabled: session.blockingEnabled,
            shieldMaintained: session.shieldMaintained && !removedEarly,
            forcedShieldRemoval: session.forcedShieldRemoval || removedEarly
        )
        if observation.assessment == .tampered, grade != .collapsed {
            grade = .open
        }
        return grade
    }
}
