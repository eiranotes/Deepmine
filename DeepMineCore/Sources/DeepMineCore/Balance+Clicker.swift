import Foundation

/// Clicker economy constants. Split from `Balance.swift` only to keep both files under
/// the 300-line limit — this is the same registry, and no game number lives outside it.
extension Balance {
    // MARK: Segment geometry

    public static let metersPerSegment = 4
    /// Region gates in `Balance` are expressed in metres, so at four metres per segment
    /// crystal begins at segment 60, ruins at 200, abyss at 400.
    public static let rockDamageStageCount = 4
    public static let rockSeedSalt: UInt64 = 0x5DEE_9111_4E00_0001

    // MARK: Integrity and yield

    public static let baseSegmentIntegrity = 10.0
    public static let baseSegmentOre = 4.0
    /// Integrity has to outrun the damage the ore it pays for can buy, or upgrades would
    /// have nothing to fix — but only just. Ore compounds at 1.07 per segment and a level
    /// costs 1.34, which buys ~0.23 levels of 1.12 damage, so purchased damage compounds
    /// at ~1.026545. At 1.058 integrity each segment takes 3.064% longer than the one above it:
    /// a descent that slows enough to feel deep and never enough to stop.
    ///
    /// The previous 1.085 outran purchased damage by 5.7% per segment, which compounds to
    /// a factor of 16.4 million across 300 segments. The replacement is still a factor of
    /// about 8,556, but upgrades continuously fund it instead of falling behind (D-044).
    public static let segmentIntegrityGrowthRate = 1.058
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

    // MARK: Shaft

    /// How much of the shaft the player can see at once. Depth is the number the whole
    /// game is about, so it is shown as a place rather than a label: broken rock above,
    /// the face being worked in the middle, unbroken rock fading into the dark below.
    public static let visibleLayersAbove = 3
    /// Rock below the face is only visible where the lamp reaches. Buying light is the
    /// most literal upgrade a mine can sell — the shaft opens up as it gets brighter.
    public static let baseVisibleLayersBelow = 2.0
    public static let visibleLayersPerLampLevel = 0.15
    public static let maximumVisibleLayersBelow = 8.0

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
