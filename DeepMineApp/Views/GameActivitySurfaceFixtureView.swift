import DeepMineCore
import SwiftUI

enum GameActivitySurfaceFixture {
    static let referenceDate = Date()

    static func snapshot(named name: String) -> GameSurfaceSnapshot {
        let phase: GameSurfacePhase = switch name {
        case "surface-vein", "surface-vein-unknown": .vein
        case "surface-collapsed": .collapsed
        case "surface-completed": .completed
        default: .mining
        }
        let isMining = phase == .mining
        let isCollapsed = phase == .collapsed
        return GameSurfaceSnapshot(
            phase: phase,
            sessionID: "surface-fixture-session",
            outcomeID: isMining ? nil : (isCollapsed ? "abandoned" : "completed"),
            planID: "survey",
            regionID: "ruins",
            depthMeters: 862,
            expectedOre: isMining ? 12_345 : 0,
            earnedOre: isMining ? 987_654 : (isCollapsed ? 0 : 12_345),
            streakDays: 7,
            timerStartedAt: referenceDate.addingTimeInterval(-300).timeIntervalSince1970,
            timerEndsAt: referenceDate.addingTimeInterval(1_200).timeIntervalSince1970,
            verificationGradeID: isCollapsed ? "collapsed" : "sealed",
            veinID: phase == .vein
                ? (name == "surface-vein-unknown" ? "unknown-sentinel" : "crystal")
                : (isMining ? "abyss" : nil),
            upgradeRecommendation: isMining || isCollapsed ? nil : .init(
                equipmentID: "drill",
                currentLevel: 2,
                nextLevel: 3,
                cost: 138,
                marginalExpectedOre: 24.5
            ),
            todayFocusedMinutes: 75,
            todayGoalMinutes: 100,
            generatedAt: referenceDate.timeIntervalSince1970,
            staleAfter: referenceDate.addingTimeInterval(
                Balance.completedActivityRetentionSeconds
            ).timeIntervalSince1970
        )
    }
}

struct GameActivitySurfaceFixtureView: View {
    let stateName: String
    let surfaceName: String

    private var snapshot: GameSurfaceSnapshot {
        GameActivitySurfaceFixture.snapshot(named: stateName)
    }
    private var isStale: Bool { stateName == "surface-stale" }
    private var startedAt: Date {
        Date(timeIntervalSince1970: snapshot.timerStartedAt ?? 0)
    }
    private var endsAt: Date {
        Date(timeIntervalSince1970: snapshot.timerEndsAt ?? 0)
    }

    var body: some View {
        ZStack {
            ProbePalette.coal.ignoresSafeArea()
            switch surfaceName {
            case "expanded-mark":
                SurfaceExpandedPhaseMark(snapshot: snapshot, isStale: isStale)
                    .padding(12)
            case "minimal":
                GameMinimalActivityContent(snapshot: snapshot, isStale: isStale)
                    .padding(12)
            case "compact":
                GameCompactActivityContent(
                    startedAt: startedAt,
                    endsAt: endsAt,
                    snapshot: snapshot,
                    isStale: isStale
                )
                .padding(10)
                .background(ProbePalette.shale, in: RoundedRectangle(cornerRadius: 9))
            case "expanded":
                GameExpandedActivityContent(
                    startedAt: startedAt,
                    endsAt: endsAt,
                    snapshot: snapshot,
                    isStale: isStale
                )
                .padding(12)
                .frame(maxWidth: 371, maxHeight: GameActivityLayout.expandedMaximumHeight)
                .background(ProbePalette.shale, in: RoundedRectangle(cornerRadius: 9))
            case "standby":
                GameStandByContent(
                    startedAt: startedAt,
                    endsAt: endsAt,
                    snapshot: snapshot,
                    isStale: isStale
                )
                .background(ProbePalette.shale)
            default:
                ProbeLockScreenContent(
                    startedAt: startedAt,
                    endsAt: endsAt,
                    snapshot: snapshot,
                    isStale: isStale
                )
                .frame(maxWidth: 420, maxHeight: GameActivityLayout.lockScreenMaximumHeight)
                .background(ProbePalette.shale, in: RoundedRectangle(cornerRadius: 9))
            }
        }
        .preferredColorScheme(.dark)
    }
}
