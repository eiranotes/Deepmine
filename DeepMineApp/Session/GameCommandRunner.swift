import DeepMineCore
import Foundation

/// Single place that applies queued surface commands, used both when the app becomes
/// active and when a Live Activity intent fires in the background.
@MainActor
final class GameCommandRunner: GameSurfaceCommandRunning {
    private let repository: GameRepository
    private let gameStore: GameStore
    private let surfaces: GamePassiveSurfaceRefresher
    private let queue: () throws -> GameCommandQueue
    private var isRunning = false
    private(set) var lastFailed = false

    init(
        repository: GameRepository,
        gameStore: GameStore,
        surfaces: GamePassiveSurfaceRefresher = .product,
        queue: @escaping () throws -> GameCommandQueue = { try GameCommandQueue.shared() }
    ) {
        self.repository = repository
        self.gameStore = gameStore
        self.surfaces = surfaces
        self.queue = queue
    }

    func runPendingCommands() async {
        // Two intents tapped in quick succession must not interleave a drain.
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        do {
            _ = try queue().drain(
                into: repository,
                sessionHandler: gameStore.acceptQueuedCommand
            )
            try await gameStore.resume()
            lastFailed = false
        } catch {
            lastFailed = true
            ProbeDiagnostics.record(error: error, source: "GameCommandDrain")
        }
        surfaces.refresh()
    }
}
