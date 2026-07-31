import XCTest

@MainActor
final class GameActivitySurfaceTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testKoreanStatesRenderAcrossEveryActivitySurface() {
        let states = ["mining", "completed", "vein", "collapsed"]
        let surfaces = ["minimal", "compact", "expanded", "lock", "standby"]

        for state in states {
            for surface in surfaces {
                launch(state: state, surface: surface, language: "ko")
                XCTAssertTrue(
                    element("activity-\(surface)-\(state)").waitForExistence(timeout: 5),
                    "Missing \(state) on \(surface)"
                )
                app.terminate()
            }
        }
    }

    func testKoreanDetailedSurfacesExposeTruthfulOutcomeData() {
        assertLabel("예상 광석", state: "mining", surface: "lock", language: "ko")
        assertLabel("획득 광석", state: "completed", surface: "lock", language: "ko")
        assertLabel("수정", state: "vein", surface: "standby", language: "ko")
        assertLabel("붕괴", state: "collapsed", surface: "expanded", language: "ko")
    }

    func testLockScreenPresentationStaysInsideTheSystemHeightLimit() {
        launch(state: "mining", surface: "lock", language: "ko")
        let root = element("activity-lock-mining")

        XCTAssertTrue(root.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(root.frame.height, 160.5)
        XCTAssertFalse(element("activity-standby-mining").exists)
    }

    func testEnglishSemanticsAreLocalizedForEveryTerminalState() {
        assertLabel("Mining", state: "mining", surface: "lock", language: "en")
        assertLabel("Focus promise completed", state: "completed", surface: "lock", language: "en")
        assertLabel("Rare vein found", state: "vein", surface: "standby", language: "en")
        assertLabel("Collapsed", state: "collapsed", surface: "expanded", language: "en")
    }

    func testCompactUsesShortCopyWithFullSemanticLabelsInBothLanguages() {
        let expectations = [
            ("completed", "en", "READY", "Focus promise completed"),
            ("vein", "en", "VEIN", "Rare vein found"),
            ("collapsed", "en", "DOWN", "Collapsed mine"),
            ("completed", "ko", "완료", "집중 약속 완료"),
            ("vein", "ko", "광맥", "희귀 광맥 발견"),
            ("collapsed", "ko", "붕괴", "붕괴")
        ]
        for (state, language, shortCopy, semanticLabel) in expectations {
            launch(state: state, surface: "compact", language: language)
            let status = element("activity-compact-status-\(state)")
            XCTAssertTrue(status.waitForExistence(timeout: 5))
            XCTAssertEqual(status.value as? String, shortCopy)
            XCTAssertTrue(status.label.contains(semanticLabel))
            app.terminate()
        }
    }

    func testStaleMiningProjectsOnlyToNeutralReturnReady() {
        for surface in ["minimal", "compact", "expanded", "lock", "standby"] {
            launch(state: "stale", surface: surface, language: "ko")
            XCTAssertTrue(
                element("activity-\(surface)-waiting").waitForExistence(timeout: 5),
                "Stale mining did not project to waiting on \(surface)"
            )
            XCTAssertTrue(matchingLabel("귀환 준비").exists)
            XCTAssertFalse(matchingLabel("98.8만").exists, "Stale state disclosed earned ore")
            XCTAssertFalse(matchingLabel("심연").exists, "Stale state disclosed a vein")
            app.terminate()
        }

        launch(state: "stale", surface: "expanded-mark", language: "ko")
        XCTAssertTrue(
            element("activity-expanded-mark-waiting").waitForExistence(timeout: 5)
        )
    }

    func testMiningNeverDisclosesTerminalSentinels() {
        for surface in ["expanded", "lock", "standby"] {
            launch(state: "mining", surface: surface, language: "ko")
            XCTAssertTrue(element("activity-\(surface)-mining").waitForExistence(timeout: 5))
            XCTAssertFalse(matchingLabel("98.8만").exists, "Mining disclosed earned ore")
            XCTAssertFalse(matchingLabel("심연").exists, "Mining disclosed a vein")
            app.terminate()
        }
    }

    func testCompletedExpandedActionsAndLayoutAreAccessible() {
        launch(state: "completed", surface: "expanded", language: "ko")
        let root = element("activity-expanded-completed")
        XCTAssertTrue(root.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(root.frame.height, 144.5)
        XCTAssertTrue(element("activity-start-25").exists)
        XCTAssertTrue(element("activity-start-50").exists)
        let recommendation = element("activity-upgrade-recommendation")
        XCTAssertTrue(recommendation.exists)
        for identifier in [
            "activity-upgrade-recommendation",
            "activity-start-25",
            "activity-start-50"
        ] {
            XCTAssertGreaterThanOrEqual(element(identifier).frame.height, 44)
        }
        XCTAssertTrue(recommendation.label.contains("추천 강화"))
        XCTAssertTrue(recommendation.label.contains("레벨 3"))
        XCTAssertTrue(recommendation.label.contains("비용 138"))

        app.terminate()
        launch(state: "collapsed", surface: "expanded", language: "ko")
        let open = element("activity-open")
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(open.frame.height, 44)
        XCTAssertLessThanOrEqual(element("activity-expanded-collapsed").frame.height, 144.5)
    }

    func testMiningTimerAndProgressKeepDynamicAccessibilityValues() {
        launch(state: "mining", surface: "expanded", language: "en")
        let timer = element("activity-expanded-timer")
        let progress = element("activity-expanded-progress")
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        XCTAssertTrue(progress.exists)
        XCTAssertEqual(timer.label, "Remaining time")
        XCTAssertFalse(String(describing: timer.value ?? "").isEmpty)
        XCTAssertEqual(progress.label, "Session progress")
        XCTAssertFalse(String(describing: progress.value ?? "").isEmpty)
    }

    func testStandByKnownAndUnknownVeinsNeverInventIdentity() {
        launch(state: "vein", surface: "standby", language: "ko")
        XCTAssertTrue(element("activity-standby-vein-name").waitForExistence(timeout: 5))
        XCTAssertTrue(matchingLabel("수정 광맥").exists)
        app.terminate()

        launch(state: "vein-unknown", surface: "standby", language: "ko")
        XCTAssertTrue(element("activity-standby-vein").waitForExistence(timeout: 5))
        XCTAssertTrue(matchingLabel("결과 준비").exists)
        XCTAssertFalse(matchingLabel("청색 광맥").exists)
    }

    private func assertLabel(
        _ label: String,
        state: String,
        surface: String,
        language: String
    ) {
        launch(state: state, surface: surface, language: language)
        XCTAssertTrue(element("activity-\(surface)-\(state)").waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any).matching(
                NSPredicate(format: "label CONTAINS[c] %@", label)
            ).firstMatch.exists,
            "Missing \(label) for \(state) on \(surface)"
        )
        app.terminate()
    }

    private func launch(state: String, surface: String, language: String) {
        app = XCUIApplication()
        let locale = language == "ko" ? "ko_KR" : "en_US"
        app.launchArguments += [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "-AppleInterfaceStyle", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"
        ]
        app.launchEnvironment["DEEPMINE_UI_FIXTURE"] = "surface-\(state)"
        app.launchEnvironment["DEEPMINE_ACTIVITY_SURFACE"] = surface
        app.launchEnvironment["DEEPMINE_UI_RESET"] = "1"
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = "\(name)-\(language)-\(state)-\(surface)"
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func matchingLabel(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] %@", label)
        ).firstMatch
    }
}
