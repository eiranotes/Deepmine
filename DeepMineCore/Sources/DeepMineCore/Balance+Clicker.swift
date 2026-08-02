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

    // MARK: Strike timeline

    /// One strike is a single timeline shared by the body, both hands and the tool, and the
    /// damage lands on the contact frame rather than on the input event (D-055). A quick
    /// swing reads as acceleration, a heavy one as weight; without the split every strike
    /// at 820ms felt mechanical (D-058).
    public static let quickStrikeDuration: TimeInterval = 0.560
    public static let quickStrikeContact: TimeInterval = 0.202
    public static let heavyStrikeDuration: TimeInterval = 0.690
    public static let heavyStrikeContact: TimeInterval = 0.249
    public static let criticalStrikeDuration: TimeInterval = 0.760
    public static let criticalStrikeContact: TimeInterval = 0.274
    /// Reduce Motion keeps the pose change and the reward, and drops the travel time.
    public static let reducedStrikeDuration: TimeInterval = 0.160
    public static let reducedStrikeContact: TimeInterval = 0.080
    /// A manual strike owns the actor for this long, so an automation tick cannot overwrite
    /// the pose mid-swing. Overlapped automatic damage is carried to the next contact.
    public static let manualStrikeActorGuard: TimeInterval = 0.640
    /// Automatic swing period when nothing is tapped.
    public static let automaticStrikeInterval: TimeInterval = 0.820

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

    /// Shaft space is continuous. Four metres is still one economy segment, but it is
    /// never a rendering band: the head travels through those metres before the next
    /// segment begins.
    public static let shaftPointsPerMeter = 9.0
    public static let shaftVisibleMetersAbove = 24.0
    /// Rock below the head is visible only where the lamp reaches.
    public static let baseVisibleMetersBelow = 8.0
    public static let visibleMetersPerLampLevel = 0.6
    public static let maximumVisibleMetersBelow = 36.0
    public static let reachModificationVisibleMeters = 8.0

    /// A bought drill leaves a wider permanent scar. Old records keep their original
    /// width, which makes progress readable when the player looks up the shaft.
    public static let boreWidthBasePoints = 70.0
    public static let boreWidthPerDrillLevel = 1.4
    public static let boreWidthMaximumPoints = 150.0
    public static let wideModificationBoreWidthPoints = 20.0
    public static let maximumBoreHistoryRecords = 64

    // MARK: Equipment modifications

    public static let equipmentModificationUnlockLevel = 5
    public static let drillModificationCost = 460.0
    public static let cartModificationCost = 560.0
    public static let lampModificationCost = 660.0
    public static let impactModificationDamageMultiplier = 1.35
    public static let fleetModificationAutomationMultiplier = 1.25
    public static let freightModificationOreMultiplier = 1.25
    public static let fortuneModificationCriticalChance = 0.08

    // MARK: Refinement

    /// The second multiplicative axis, and the piece the ladder alone cannot supply.
    ///
    /// A level costs 1.34 and returns 1.12 damage, so a segment's ore buys 0.2312 levels
    /// and 1.0265 damage while integrity compounds at 1.058 — a 3.064% deficit per segment
    /// at any ceiling. Cookie Clicker solves the same shape not by making levels steeper
    /// but by adding stepped upgrades that multiply; refinement is that step.
    ///
    /// A segment buys 0.2312 levels, so a tier every N levels contributes 2.5^(0.2312/N)
    /// per segment. Six levels lands the combined rate at 1.0633 against integrity's 1.058
    /// — +0.50% of headroom, enough that the descent gently accelerates and not so much
    /// that it trivialises itself. Seven is the exact balance point (+0.0%) and five
    /// overshoots to +1.21%.
    ///
    /// Six levels is also 90m of depth at one level per 15m, which puts refinement on
    /// roughly the same rhythm as the 100m seam the shaft already beats.
    public static let refinementLevelInterval = 6
    public static let refinementDamageMultiplier = 2.5
    /// Refinement is bought with ore, and that is not a detail.
    ///
    /// The first draft priced it in crystals, which come from veins, which come from
    /// sessions. That handed the multiplicative axis to whoever ran the most sessions and
    /// x2.5^n turned a session-count difference into an exponential one — a 1.6e10x spread
    /// at 180 days, with focus owning the economy instead of amplifying it (D-037).
    ///
    /// Ore comes out of rock, so every player earns it with or without focus. Competing
    /// with levels for the same currency is the point rather than a flaw: it is the first
    /// real spending decision in the game.
    ///
    /// Priced as a multiple of the level that unlocks it, so the cost rides the same
    /// 1.34^n curve the ladder does. A tier is worth about eight levels of damage
    /// (1.12^8 = 2.48 against x2.5) and eight levels cost roughly 29x one level, so 20x
    /// keeps refinement attractive without making it strictly better than climbing.
    public static let refinementCostMultiplier = 20.0

    // MARK: Infrastructure

    /// Equipment levels become visible plant in the passage, not just larger numbers
    /// (D-059). Counts are deliberately small: four carts on a rail read as an operation,
    /// twelve read as clutter.
    public static let maximumSupportCrew = 4
    /// Total equipment level at which the first extra crew member appears. Below it the
    /// mine is one miner, which is what the opening minutes should look like.
    public static let supportCrewLevelOffset = 10
    public static let maximumCarts = 4
    public static let maximumCargoSlots = 3
    public static let maximumServiceLamps = 5
    /// Levels between each additional cart or cargo slot.
    public static let cartGrowthLevelStep = 2

    // MARK: Resonance node

    /// A rare, explicit reward the player has to notice and press — distinct from the
    /// resonance *vein*, which is a session payout the mine hands over on its own (D-057).
    /// Naming them apart matters: one is a thing you catch, the other is a thing you receive.
    ///
    /// The first one arrives early so the mechanic is taught while the player is still
    /// watching; after that the gap is long enough that the shaft is not a whack-a-mole.
    public static let resonanceNodeFirstDelay: TimeInterval = 5.2
    public static let resonanceNodeMinimumDelay: TimeInterval = 120
    public static let resonanceNodeMaximumDelay: TimeInterval = 300
    /// Long enough to notice and reach, short enough that ignoring it is a real loss.
    public static let resonanceNodeActiveWindow: TimeInterval = 12
    public static let resonanceNodeBoostDuration: TimeInterval = 18
    public static let resonanceNodeSettleDelay: TimeInterval = 1.5
    /// Doubles what the player is already producing rather than paying a flat sum, so the
    /// reward grows with the mine instead of becoming irrelevant.
    public static let resonanceNodeMultiplier = 2.0

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

    /// How many times one call may re-drive a truncated resolution. Each pass walks up to
    /// `maximumSegmentsPerResolution` segments, so this bounds the work while still letting
    /// an extreme offline haul finish instead of losing its tail.
    public static let maximumResolutionPasses = 12

    /// A single resolution never breaks more than this many segments. Offline catch-up
    /// can imply thousands; the caller is told it was truncated rather than being handed
    /// a silently wrong result or an unbounded loop.
    public static let maximumSegmentsPerResolution = 512
}
