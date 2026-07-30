import Foundation

/// A `LiveActivityIntent` runs inside the app process even when the app is in the
/// background, so a Dynamic Island button can do more than leave a note for later.
/// The app registers itself here at launch; the widget process never does and falls
/// back to queue-only behaviour, which is all it can do anyway.
@MainActor
protocol GameSurfaceCommandRunning: AnyObject {
    func runPendingCommands() async
}

@MainActor
enum GameSurfaceCommandRunner {
    private static weak var registered: (any GameSurfaceCommandRunning)?

    static func register(_ runner: any GameSurfaceCommandRunning) {
        registered = runner
    }

    /// Applies anything sitting in the queue. Safe to call from any process: without a
    /// registered runner the command stays queued for the next foreground launch.
    static func runQueuedCommands() async {
        await registered?.runPendingCommands()
    }
}
