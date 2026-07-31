import Foundation

/// Clicker economy constants. Split from `Balance.swift` only to keep both files under
/// the 300-line limit — this is the same registry, and no game number lives outside it.
extension Balance {
    // MARK: Segment geometry

    public static let metersPerSegment = 4
    /// Region gates in `Balance` are expressed in metres, so at four metres per segment
    /// crystal begins at segment 30, ruins at 120, abyss at 300.
    public static let rockDamageStageCount = 4
    public static let rockSeedSalt: UInt64 = 0x5DEE_9111_4E00_0001

    // MARK: Integrity and yield

    public static let baseSegmentIntegrity = 10.0
    public static let baseSegmentOre = 4.0
    /// Integrity outruns ore by ~1.4% per segment. That widening gap is the entire reason
    /// upgrades exist: without it, the first drill would carry a player to the abyss and
    /// the economy would have nothing left to sell.
    public static let segmentIntegrityGrowthRate = 1.085
    public static let segmentOreGrowthRate = 1.07

    public static let seamSegmentInterval = 25
    public static let seamIntegrityMultiplier = 6.0
    /// Seams pay far more than they cost, so the wall you just spent a minute on
    /// resolves into a visible jump rather than another identical rock.
    public static let seamOreMultiplier = 15.0

    public static let entryRegionOreMultiplier = 1.0
    public static let crystalRegionOreMultiplier = 1.35
    public static let ruinsRegionOreMultiplier = 1.8
    public static let abyssRegionOreMultiplier = 2.4

    // MARK: Weak points

    public static let weakPointChance = 0.35
    public static let weakPointDamageMultiplier = 3.0
    public static let weakPointRegionMultiplierStep = 0.5
    public static let weakPointEdgeInset = 0.18

    // MARK: Striking

    /// The three existing tools take clicker roles rather than being replaced: the drill
    /// is the hand, the cart is the machine, the lamp is luck. Their compounding rates
    /// are the ones already tuned in `Balance`, so one upgrade curve drives both economies.
    public static let baseTapDamage = 1.0
    public static let baseCriticalChance = 0.05
    public static let baseCriticalMultiplier = 2.5
    public static let lampCriticalChanceIncreasePerLevel = 0.01
    public static let lampCriticalMultiplierIncreasePerLevel = 0.03
    public static let maximumCriticalChance = 0.6

    /// The impact meter fills as taps land and decays when they stop, so sustained
    /// tapping beats the same number of taps spread thin. This is the active-play reward
    /// that does not replace idle output.
    public static let impactMeterMaximum = 100.0
    public static let impactPerTap = 7.0
    public static let impactDecayPerSecond = 9.0
    public static let impactFullDamageMultiplier = 2.0

    // MARK: Automation

    /// A cart at base level hauls nothing on its own. The first cart upgrade is the
    /// moment the mine starts running without you, which is the beat every idle game is
    /// built around — it should be bought, not given.
    public static let automationDamagePerLevel = 0.5
    public static let automationGrowthRate = 1.12
    /// Seconds of automation folded into one simulation step. Long enough that a step is
    /// cheap, short enough that the ore counter still moves visibly.
    public static let automationStepSeconds: TimeInterval = 0.25

    // MARK: Offline

    /// The mine keeps working while the app is closed, but not forever. A cap is what
    /// makes returning worth doing daily instead of once a month — and it is the honest
    /// alternative to a game that plays itself completely.
    public static let maximumOfflineHours: TimeInterval = 8
    /// Offline pays less than being present. Enough that closing the app is never the
    /// optimal strategy, not so little that sleeping feels punished.
    public static let offlineEfficiency = 0.75
    /// Below this, a return is not worth interrupting the player with a sheet.
    public static let minimumOfflineSecondsToReport: TimeInterval = 60
    /// A clock that jumped backwards, or a wildly future timestamp, settles nothing
    /// rather than paying out a fabricated haul.
    public static let maximumPlausibleOfflineSeconds: TimeInterval = 60 * 60 * 24 * 30

    /// A single resolution never breaks more than this many segments. Offline catch-up
    /// can imply thousands; the caller is told it was truncated rather than being handed
    /// a silently wrong result or an unbounded loop.
    public static let maximumSegmentsPerResolution = 512
}
