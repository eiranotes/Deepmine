import Foundation

struct CompletedGameSurfaceResult: Sendable {
    let snapshot: GameSurfaceSnapshot?
    let warnings: [String]
}

@MainActor
extension GameStore {
    @discardableResult
    func publishWaitingSurface() async throws -> Bool {
        let player = try repository.loadPlayer()
        let snapshot = try GameSurfaceSnapshotMapper.waiting(
            player: player,
            recommendation: try recommendedUpgrade(),
            at: clock.wallNow(),
            calendar: calendar,
            timeZone: timeZone
        )
        return await coordinator.publishWaiting(snapshot)
    }

    func dismissReturnReport() async throws {
        try repository.clearReturnReport()
        returnReport = nil
        _ = try await publishWaitingSurface()
    }

    func completedSurfaceResult(
        for report: GameReturnReport
    ) -> CompletedGameSurfaceResult {
        do {
            let player = try repository.loadPlayer()
            let presentation = try returnPresentation(for: report)
            let snapshot = try GameSurfaceSnapshotMapper.returned(
                presentation: presentation,
                player: player,
                at: report.completedAt,
                calendar: calendar,
                timeZone: timeZone
            )
            return CompletedGameSurfaceResult(snapshot: snapshot, warnings: [])
        } catch {
            return CompletedGameSurfaceResult(
                snapshot: nil,
                warnings: ["완료 정보를 공유 표면에 준비하지 못했습니다."]
            )
        }
    }

    func finishCleanup(
        session: PersistedGameSession,
        report: GameReturnReport
    ) async throws -> GameReturnReport {
        let surface = completedSurfaceResult(for: report)
        let warnings = await coordinator.finish(
            session,
            completedSnapshot: surface.snapshot
        )
        let updated = report.adding(warnings: surface.warnings + warnings)
        try repository.finishSessionCleanup(report: updated)
        activeSession = nil
        returnReport = updated
        visibleReason = updated.warnings.first
        return updated
    }
}
