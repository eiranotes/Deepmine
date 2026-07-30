import Foundation

public enum SessionTransitionError: Error, Codable, Equatable, Sendable {
    case illegalTransition(from: SessionPhase, action: SessionAction)
    case nonMonotonicTimestamp
}

public struct SessionStateMachine: Codable, Equatable, Sendable {
    public private(set) var phase: SessionPhase
    public let preparedAt: Date
    public private(set) var startedAt: Date?
    public private(set) var endedAt: Date?
    public private(set) var completionID: UUID?

    public init(preparedAt: Date) {
        phase = .preparing
        self.preparedAt = preparedAt
        startedAt = nil
        endedAt = nil
        completionID = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let phase = try container.decode(SessionPhase.self, forKey: .phase)
        let preparedAt = try container.decode(Date.self, forKey: .preparedAt)
        let startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        let endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        let completionID = try container.decodeIfPresent(UUID.self, forKey: .completionID)
        guard Self.isValid(
            phase: phase,
            preparedAt: preparedAt,
            startedAt: startedAt,
            endedAt: endedAt,
            completionID: completionID
        ) else {
            throw DecodingError.dataCorruptedError(
                forKey: .phase,
                in: container,
                debugDescription: "Session state does not match its phase"
            )
        }
        self.phase = phase
        self.preparedAt = preparedAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.completionID = completionID
    }

    public mutating func start(at timestamp: Date) throws {
        guard phase == .preparing else {
            throw SessionTransitionError.illegalTransition(from: phase, action: .start)
        }
        guard timestamp >= preparedAt else {
            throw SessionTransitionError.nonMonotonicTimestamp
        }
        phase = .mining
        startedAt = timestamp
    }

    public mutating func complete(at timestamp: Date, completionID: UUID) throws {
        try finish(
            as: .completed,
            action: .complete,
            at: timestamp,
            completionID: completionID
        )
    }

    public mutating func abandon(at timestamp: Date, completionID: UUID) throws {
        try finish(
            as: .abandoned,
            action: .abandon,
            at: timestamp,
            completionID: completionID
        )
    }

    private mutating func finish(
        as terminalPhase: SessionPhase,
        action: SessionAction,
        at timestamp: Date,
        completionID: UUID
    ) throws {
        guard phase == .mining else {
            throw SessionTransitionError.illegalTransition(from: phase, action: action)
        }
        guard let startedAt, timestamp >= startedAt else {
            throw SessionTransitionError.nonMonotonicTimestamp
        }
        phase = terminalPhase
        endedAt = timestamp
        self.completionID = completionID
    }

    private static func isValid(
        phase: SessionPhase,
        preparedAt: Date,
        startedAt: Date?,
        endedAt: Date?,
        completionID: UUID?
    ) -> Bool {
        switch phase {
        case .preparing:
            return startedAt == nil && endedAt == nil && completionID == nil
        case .mining:
            return startedAt.map { $0 >= preparedAt } == true
                && endedAt == nil && completionID == nil
        case .completed, .abandoned:
            guard let startedAt, let endedAt, completionID != nil else { return false }
            return startedAt >= preparedAt && endedAt >= startedAt
        }
    }
}
