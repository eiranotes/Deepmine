import XCTest
@testable import DeepMineCore

final class StrikeTimelineTests: XCTestCase {
    func testEachVariantUsesItsOwnWeight() {
        let quick = StrikeTimeline.timeline(for: .quick)
        let heavy = StrikeTimeline.timeline(for: .heavy)
        let critical = StrikeTimeline.timeline(for: .critical)

        XCTAssertLessThan(quick.duration, heavy.duration)
        XCTAssertLessThan(heavy.duration, critical.duration)
        XCTAssertLessThan(quick.contact, heavy.contact)
        XCTAssertLessThan(heavy.contact, critical.contact)
    }

    /// Contact has to happen inside the swing, or damage would land after the actor has
    /// already returned to ready.
    func testContactAlwaysPrecedesTheEndOfTheSwing() {
        for variant in StrikeVariant.allCases {
            for reduceMotion in [true, false] {
                let timeline = StrikeTimeline.timeline(for: variant, reduceMotion: reduceMotion)
                XCTAssertGreaterThan(timeline.contact, 0)
                XCTAssertLessThan(timeline.contact, timeline.duration)
            }
        }
    }

    func testReduceMotionShortensEveryVariantToTheSameShortSwing() {
        let timelines = StrikeVariant.allCases.map {
            StrikeTimeline.timeline(for: $0, reduceMotion: true)
        }
        XCTAssertEqual(Set(timelines.map(\.duration)).count, 1)
        for timeline in timelines {
            XCTAssertLessThan(timeline.duration, StrikeTimeline.timeline(for: .quick).duration)
        }
    }

    /// The frame the player sees at contact must be the contact frame. If these disagree,
    /// the rock loses integrity while the pickaxe is still in the air — the exact defect
    /// binding the actor into one strip was meant to remove.
    func testTheContactFrameIsShowingWhenDamageLands() {
        for variant in StrikeVariant.allCases {
            let timeline = StrikeTimeline.timeline(for: variant)
            XCTAssertEqual(timeline.frameIndex(at: timeline.contact), 2, "\(variant)")
        }
    }

    func testTheSwingRunsReadyAnticipationContactRecoilAndBack() {
        let timeline = StrikeTimeline.timeline(for: .quick)
        XCTAssertEqual(timeline.frameIndex(at: 0), 0)
        XCTAssertEqual(timeline.frameIndex(at: timeline.contact * 0.2), 1)
        XCTAssertEqual(timeline.frameIndex(at: timeline.contact), 2)
        XCTAssertEqual(timeline.frameIndex(at: timeline.duration * 0.95), 3)
        XCTAssertEqual(timeline.frameIndex(at: timeline.duration), 0)
        XCTAssertEqual(timeline.frameIndex(at: timeline.duration * 4), 0)
    }

    /// The defect this cadence exists to prevent: automation advances the rock every 0.25s,
    /// and triggering a 0.56s swing that often restarts it before it can finish — the miner
    /// freezes on anticipation while the rock keeps breaking.
    func testAutomaticSwingsDoNotRestartOnEverySimulationStep() {
        let step = Balance.automationStepSeconds
        var lastSwing: TimeInterval? = nil
        var starts = 0
        var now: TimeInterval = 0

        while now < Balance.automaticStrikeInterval * 3 {
            if StrikeTimeline.Cadence.shouldStartAutomaticSwing(
                now: now,
                lastSwingAt: lastSwing,
                lastManualStrikeAt: nil
            ) {
                starts += 1
                lastSwing = now
            }
            now += step
        }

        XCTAssertEqual(starts, 3)
    }

    func testATapOwnsTheActorForItsGuardWindow() {
        XCTAssertTrue(StrikeTimeline.Cadence.manualOwnsActor(now: 0.1, lastManualStrikeAt: 0))
        XCTAssertFalse(
            StrikeTimeline.Cadence.manualOwnsActor(
                now: Balance.manualStrikeActorGuard + 0.01,
                lastManualStrikeAt: 0
            )
        )
        XCTAssertFalse(StrikeTimeline.Cadence.manualOwnsActor(now: 5, lastManualStrikeAt: nil))
    }

    func testAutomaticSwingsYieldWhileATapOwnsTheActor() {
        XCTAssertFalse(StrikeTimeline.Cadence.shouldStartAutomaticSwing(
            now: 10,
            lastSwingAt: 0,
            lastManualStrikeAt: 9.9
        ))
        XCTAssertTrue(StrikeTimeline.Cadence.shouldStartAutomaticSwing(
            now: 10,
            lastSwingAt: 0,
            lastManualStrikeAt: 9.9 - Balance.manualStrikeActorGuard
        ))
    }

    func testConsecutiveSwingsAlternateAndCriticalsAlwaysReadHeaviest() {
        XCTAssertEqual(StrikeTimeline.Cadence.variant(sequence: 0, wasCritical: false), .quick)
        XCTAssertEqual(StrikeTimeline.Cadence.variant(sequence: 1, wasCritical: false), .heavy)
        XCTAssertEqual(StrikeTimeline.Cadence.variant(sequence: 2, wasCritical: false), .quick)
        XCTAssertEqual(StrikeTimeline.Cadence.variant(sequence: 7, wasCritical: true), .critical)
    }

    func testFrameIndexNeverLeavesTheStrip() {
        let timeline = StrikeTimeline.timeline(for: .critical)
        for step in 0...100 {
            let elapsed = timeline.duration * Double(step) / 100
            let index = timeline.frameIndex(at: elapsed)
            XCTAssertTrue((0..<4).contains(index))
        }
        XCTAssertEqual(timeline.frameIndex(at: 0.1, frameCount: 1), 0)
    }
}
