import Foundation

public enum NextStepKind: String, Codable, Equatable, Sendable {
    case equipment
    case region
    case streak
    case crew
}

/// One reachable goal, expressed as progress toward a threshold.
///
/// `remainingSessions` is an estimate and the UI must say so. No hidden randomness ever
/// lengthens the distance shown here.
public struct NextStep: Codable, Equatable, Sendable {
    public let kind: NextStepKind
    public let current: Int
    public let target: Int
    public let remainingSessions: Int?
    public let detail: String?

    public var fraction: Double {
        guard target > 0 else { return 1 }
        return min(1, max(0, Double(current) / Double(target)))
    }

    public init(
        kind: NextStepKind,
        current: Int,
        target: Int,
        remainingSessions: Int? = nil,
        detail: String? = nil
    ) {
        self.kind = kind
        self.current = current
        self.target = target
        self.remainingSessions = remainingSessions
        self.detail = detail
    }
}

public enum NextStepPlanner {
    public static let maximumSteps = 3

    /// The next few goals reachable with the plan the player already has selected.
    /// Ordered nearest-first and capped, so the home screen shows a horizon rather than
    /// a backlog.
    public static func steps(
        for state: PlayerState,
        expectedOrePerSession: Double
    ) -> [NextStep] {
        var steps: [NextStep] = []
        if let equipment = equipmentStep(for: state, expectedOrePerSession: expectedOrePerSession) {
            steps.append(equipment)
        }
        if let region = regionStep(for: state) {
            steps.append(region)
        }
        if let streak = streakStep(for: state) {
            steps.append(streak)
        }
        if steps.count < maximumSteps, let crew = crewStep(for: state) {
            steps.append(crew)
        }
        return Array(steps.prefix(maximumSteps))
    }

    private static func equipmentStep(
        for state: PlayerState,
        expectedOrePerSession: Double
    ) -> NextStep? {
        let unlocked = EquipmentEngine.unlockedMaximumLevel(in: state)
        let candidates = EquipmentKind.allCases.compactMap { kind -> (UpgradeQuote, Int)? in
            guard let quote = EquipmentEngine.quote(for: kind, in: state),
                  quote.currentLevel < unlocked else { return nil }
            return (quote, quote.currentLevel)
        }
        guard let cheapest = candidates.min(by: { $0.0.cost < $1.0.cost }) else { return nil }
        let quote = cheapest.0
        let missing = max(0, quote.cost - state.resources.ore)
        return NextStep(
            kind: .equipment,
            current: Int(min(Double(Int.max), state.resources.ore)),
            target: Int(min(Double(Int.max), quote.cost)),
            remainingSessions: sessions(forMissingOre: missing, perSession: expectedOrePerSession),
            detail: quote.equipment.rawValue
        )
    }

    private static func regionStep(for state: PlayerState) -> NextStep? {
        let depth = state.depthMeters
        guard let next = WorldProgression.nextRegionThreshold(afterDepth: depth) else {
            return nil
        }
        return NextStep(
            kind: .region,
            current: depth,
            target: next.depth,
            remainingSessions: nil,
            detail: next.region.rawValue
        )
    }

    private static func streakStep(for state: PlayerState) -> NextStep? {
        let tiers = [
            Balance.streakDayThree,
            Balance.streakDaySeven,
            Balance.streakDayFourteen,
            Balance.streakDayThirty
        ]
        guard let target = tiers.first(where: { $0 > state.streakDays }) else { return nil }
        return NextStep(kind: .streak, current: state.streakDays, target: target)
    }

    private static func crewStep(for state: PlayerState) -> NextStep? {
        guard let level = MineCrew.nextGrowthDrillLevel(drillLevel: state.equipment.drill) else {
            return nil
        }
        return NextStep(
            kind: .crew,
            current: state.equipment.drill,
            target: level,
            detail: "\(MineCrew.size(for: state) + 1)"
        )
    }

    private static func sessions(forMissingOre missing: Double, perSession: Double) -> Int? {
        guard missing > 0 else { return 0 }
        guard perSession.isFinite, perSession > 0 else { return nil }
        let value = (missing / perSession).rounded(.up)
        guard value.isFinite, value < Double(Int.max) else { return nil }
        return Int(value)
    }
}
