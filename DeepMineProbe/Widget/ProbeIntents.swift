import AppIntents
import DeepMineCore
import Foundation

struct StartSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "surface.intent.start"
    static let supportedModes: IntentModes = [.background]

    @Parameter(title: "surface.intent.length.parameter") var lengthID: String
    @Parameter(title: "surface.intent.plan.parameter") var planID: String

    init() {
        lengthID = SessionLength.minutes25.rawValue
        planID = MinePlan.safe.rawValue
    }

    init(length: SessionLength, planID: String) {
        self.lengthID = length.rawValue
        self.planID = planID
    }

    func perform() async throws -> some IntentResult {
        guard let length = SessionLength(rawValue: lengthID),
              let plan = MinePlan(rawValue: planID) else {
            throw GameSurfaceIntentError.invalidSessionParameters
        }
        try GameCommandEnqueuer.shared().enqueue(
            GameCommand(action: .startSession(length: length, plan: plan))
        )
        // Enqueue first so the command survives a crash, then apply it now: shields,
        // the alarm and the Live Activity all have to happen for the button to mean
        // what it says.
        await GameSurfaceCommandRunner.runQueuedCommands()
        return .result()
    }
}

struct AbandonSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "surface.intent.abandon"
    static let supportedModes: IntentModes = [.background]

    func perform() async throws -> some IntentResult {
        try GameCommandEnqueuer.shared().enqueue(GameCommand(action: .abandonSession))
        // Leaving early has to lift the shield immediately. Deferring this to the next
        // launch would keep a player blocked out of the app they are trying to reach.
        await GameSurfaceCommandRunner.runQueuedCommands()
        return .result()
    }
}

struct AcceptUpgradeIntent: AppIntent {
    static let title: LocalizedStringResource = "surface.intent.upgrade"
    static let supportedModes: IntentModes = [.background]

    @Parameter(title: "surface.intent.equipment.parameter") var equipmentID: String

    init() { equipmentID = EquipmentKind.drill.rawValue }
    init(equipmentID: String) { self.equipmentID = equipmentID }

    func perform() async throws -> some IntentResult {
        guard let equipment = EquipmentKind(rawValue: equipmentID) else {
            throw GameSurfaceIntentError.invalidEquipmentID
        }
        try GameCommandEnqueuer.shared().enqueue(
            GameCommand(action: .upgradeEquipment(equipment))
        )
        await GameSurfaceCommandRunner.runQueuedCommands()
        return .result()
    }
}

struct OpenGameIntent: AppIntent {
    static let title: LocalizedStringResource = "surface.intent.open"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult { .result() }
}

struct OpenAndStartSafeMineIntent: AppIntent {
    static let title: LocalizedStringResource = "surface.intent.safe25"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        let store = try GameSurfaceSnapshotStore.shared()
        if let action = GameSystemEntryPolicy.startAction(for: try store.read()) {
            try GameCommandEnqueuer.shared().enqueue(
                GameCommand(action: action)
            )
        }
        return .result()
    }
}

private enum GameSurfaceIntentError: Error {
    case invalidEquipmentID
    case invalidSessionParameters
}
