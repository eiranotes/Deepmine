import Foundation

public enum ProgressionApplicationResult: String, Codable, Equatable, Sendable {
    case applied
    case duplicate
}

public enum ProgressionError: Error, Codable, Equatable, Sendable {
    case mismatchedCompletionID
    case invalidReward
    case invalidState
}

public enum ProgressionEngine {
    public static func depth(
        lifetimeFocusCredits: Double,
        bonusDepthMeters: Int = 0
    ) -> Int {
        guard lifetimeFocusCredits.isFinite, lifetimeFocusCredits > 0 else {
            return max(0, bonusDepthMeters)
        }
        let calculated = floor(
            Balance.depthCoefficient * pow(lifetimeFocusCredits, Balance.depthExponent)
        )
        let safeBase = calculated.isFinite && calculated < Double(Int.max)
            ? Int(calculated)
            : Int.max
        let bonus = max(0, bonusDepthMeters)
        return safeBase > Int.max - bonus ? Int.max : safeBase + bonus
    }

    @discardableResult
    public static func apply(
        reward: RewardResult,
        input: RewardInput,
        completedAt: Date,
        to state: inout PlayerState
    ) throws -> ProgressionApplicationResult {
        guard reward.completionID == input.completionID else {
            throw ProgressionError.mismatchedCompletionID
        }
        guard !reward.wasDuplicate,
              !state.appliedCompletionIDs.contains(reward.completionID) else {
            return .duplicate
        }
        guard reward.ore.isFinite, reward.ore >= 0,
              reward.focusCredits.isFinite, reward.focusCredits >= 0 else {
            throw ProgressionError.invalidReward
        }
        guard state.resources.ore.isFinite, state.resources.ore >= 0,
              state.runFocusCredits.isFinite, state.runFocusCredits >= 0,
              state.lifetimeFocusCredits.isFinite, state.lifetimeFocusCredits >= 0 else {
            throw ProgressionError.invalidState
        }

        state.resources.ore = finiteSum(state.resources.ore, reward.ore)
        state.runFocusCredits = finiteSum(state.runFocusCredits, reward.focusCredits)
        state.lifetimeFocusCredits = finiteSum(
            state.lifetimeFocusCredits,
            reward.focusCredits
        )
        let completed: Bool
        switch input.outcome {
        case .completed:
            if state.completedSessionCount < Int.max {
                state.completedSessionCount += 1
            }
            completed = true
        case .abandoned:
            completed = false
        }
        state.appliedCompletionIDs.insert(reward.completionID)
        state.history.append(SessionHistoryEntry(
            completionID: reward.completionID,
            endedAt: completedAt,
            focusedMinutes: reward.focusedMinutes,
            focusCredits: reward.focusCredits,
            plan: input.plan,
            verificationGrade: input.verificationGrade,
            oreEarned: reward.ore,
            vein: input.vein,
            depthAfter: state.depthMeters,
            completed: completed
        ))
        if state.history.count > Balance.sessionHistoryLimit {
            state.history.removeFirst(state.history.count - Balance.sessionHistoryLimit)
        }
        return .applied
    }

    private static func finiteSum(_ current: Double, _ addition: Double) -> Double {
        guard current <= Double.greatestFiniteMagnitude - addition else {
            return Double.greatestFiniteMagnitude
        }
        return current + addition
    }
}
