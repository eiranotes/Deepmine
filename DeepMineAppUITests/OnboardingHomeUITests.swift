import XCTest

@MainActor
final class OnboardingHomeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testFreshLaunchStartsOnTheBreakableRockAndPersistsTheReward() {
        let storeID = "first-rock-\(UUID().uuidString)"
        launch(fixture: "fresh", reset: true, storeID: storeID)
        XCTAssertTrue(app.staticTexts["onboarding-demo-active"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["onboarding-demo-rock"].exists)
        tapFirstRockUntilReward()
        XCTAssertTrue(app.staticTexts["onboarding-demo-reward"].waitForExistence(timeout: 3))

        app.terminate()
        launch(fixture: "fresh", reset: false, storeID: storeID)
        XCTAssertTrue(app.staticTexts["onboarding-demo-reward"].waitForExistence(timeout: 5))
    }

    func testDeterministicDemoCompletionShowsRewardAndSavedUpgrade() {
        launch(fixture: "demo-completed", reset: true)
        XCTAssertTrue(app.staticTexts["onboarding-demo-reward"].waitForExistence(timeout: 5))
        app.buttons["onboarding-demo-upgrade"].tap()
        XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["onboarding-permission-focusProtection"].exists)
        app.terminate()
        launch(fixture: "demo-completed", reset: false)
        XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 5))
    }

    func testLegacyPermissionStageCanStillDeferIntoPlayableHome() {
        launch(fixture: "permissions", reset: true)
        for _ in 0..<3 {
            XCTAssertTrue(app.buttons["onboarding-permission-defer"].waitForExistence(timeout: 3))
            app.buttons["onboarding-permission-defer"].tap()
        }
        XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 3))
    }

    func testFreshAndProgressedHomeUseOneMineControlScene() {
        launch(fixture: "home-fresh", reset: true)
        XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["rock-face"].waitForExistence(timeout: 5))
        openFocusAmplifier()
        XCTAssertTrue(app.staticTexts["mine-home-deep-lock-reason"].exists)
        app.terminate()

        launch(fixture: "home-progressed", reset: true)
        XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 5))
        openFocusAmplifier()
        XCTAssertTrue(app.buttons["mine-home-plan-safe"].isSelected)
        XCTAssertTrue(app.buttons["mine-home-start"].exists)
    }

    func testDeepPlanIsLockedThenUnlocked() {
        launch(fixture: "home-fresh", reset: true)
        openFocusAmplifier()
        let locked = app.buttons["mine-home-plan-deep"]
        XCTAssertTrue(locked.waitForExistence(timeout: 5))
        XCTAssertFalse(locked.isEnabled)
        XCTAssertTrue(app.staticTexts["mine-home-deep-lock-reason"].exists)
        app.terminate()

        launch(fixture: "home-unlocked", reset: true)
        openFocusAmplifier()
        let unlocked = app.buttons["mine-home-plan-deep"]
        XCTAssertTrue(unlocked.waitForExistence(timeout: 5))
        XCTAssertTrue(unlocked.isEnabled)
        unlocked.tap()
        XCTAssertTrue(unlocked.isSelected)
    }

    func testPlanAndDurationSelectionPersistAcrossRelaunch() {
        let storeID = "selection-\(UUID().uuidString)"
        launch(fixture: "home-unlocked", reset: true, storeID: storeID)
        openFocusAmplifier()
        app.buttons["mine-home-plan-deep"].tap()
        let duration = app.buttons["mine-home-duration-50"]
        if !duration.isHittable { app.swipeUp() }
        duration.tap()
        XCTAssertTrue(app.buttons["mine-home-plan-deep"].isSelected)
        XCTAssertTrue(duration.isSelected)
        app.terminate()

        launch(fixture: "home-unlocked", reset: false, storeID: storeID)
        openFocusAmplifier()
        XCTAssertTrue(app.buttons["mine-home-plan-deep"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["mine-home-plan-deep"].isSelected)
        let reloadedDuration = app.buttons["mine-home-duration-50"]
        if !reloadedDuration.isHittable { app.swipeUp() }
        XCTAssertTrue(reloadedDuration.isSelected)
    }

    private func launch(
        fixture: String,
        reset: Bool,
        permission: String = "granted",
        storeID: String? = nil
    ) {
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleInterfaceStyle", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"
        ]
        app.launchEnvironment["DEEPMINE_UI_FIXTURE"] = fixture
        app.launchEnvironment["DEEPMINE_UI_RESET"] = reset ? "1" : "0"
        app.launchEnvironment["DEEPMINE_UI_PERMISSION"] = permission
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = storeID
            ?? "\(name)-\(fixture)-\(permission)"
        app.launch()
    }

    private func tapFirstRockUntilReward() {
        for _ in 0..<20 {
            if app.staticTexts["onboarding-demo-reward"].exists { return }
            let rock = app.buttons["onboarding-demo-rock"]
            XCTAssertTrue(rock.waitForExistence(timeout: 2))
            rock.tap()
        }
    }

    private func openFocusAmplifier() {
        let amplifier = app.buttons["mine-home-focus-amplifier"]
        for _ in 0..<10 where !amplifier.exists || !amplifier.isHittable { app.swipeUp() }
        XCTAssertTrue(amplifier.waitForExistence(timeout: 5))
        XCTAssertTrue(amplifier.isHittable)
        amplifier.tap()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
