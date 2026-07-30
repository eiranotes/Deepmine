import Foundation

/// How many miners the shaft shows.
///
/// Purely derived from equipment the player already owns and deliberately absent from
/// every reward formula: the crew is visual evidence that the mine grew, not a
/// production input. Making it pay would turn it into idle output, which the product
/// does not have (Spec §1.2).
public enum MineCrew {
    public static func size(drillLevel: Int) -> Int {
        let bounded = max(Balance.minimumEquipmentLevel, drillLevel)
        let derived = 1 + (bounded - Balance.minimumEquipmentLevel) / Balance.minerCrewStep
        return min(Balance.maximumMinerCrew, derived)
    }

    public static func size(for state: PlayerState) -> Int {
        size(drillLevel: state.equipment.drill)
    }

    /// Drill level at which the crew next grows, or nil once it is full.
    public static func nextGrowthDrillLevel(drillLevel: Int) -> Int? {
        guard size(drillLevel: drillLevel) < Balance.maximumMinerCrew else { return nil }
        let bounded = max(Balance.minimumEquipmentLevel, drillLevel)
        let stepsTaken = (bounded - Balance.minimumEquipmentLevel) / Balance.minerCrewStep
        return Balance.minimumEquipmentLevel + (stepsTaken + 1) * Balance.minerCrewStep
    }
}
