import XCTest

@MainActor
final class OnboardingHomeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTwoPremisePagesLeadToPersistedDemoStart() {
        launch(fixture: "fresh", reset: true)
        XCTAssertTrue(app.staticTexts["onboarding-premise-blocks"].waitForExistence(timeout: 5))
        app.buttons["onboarding-next"].tap()
        XCTAssertTrue(app.staticTexts["onboarding-premise-sessions"].waitForExistence(timeout: 2))
        app.buttons["onboarding-next"].tap()
        app.buttons["onboarding-demo-start"].tap()
        XCTAssertTrue(app.staticTexts["onboarding-demo-active"].waitForExistence(timeout: 2))
        let timer = app.staticTexts["onboarding-demo-timer"]
        XCTAssertTrue(timer.exists)
        XCTAssertFalse(timer.label.contains("90분") || timer.label.contains("90 minutes"))
    }

    func testDeterministicDemoCompletionShowsRewardAndSavedUpgrade() {
        launch(fixture: "demo-completed", reset: true)
        XCTAssertTrue(app.staticTexts["onboarding-demo-reward"].waitForExistence(timeout: 5))
        app.buttons["onboarding-demo-upgrade"].tap()
        XCTAssertTrue(
            app.staticTexts["onboarding-permission-focusProtection"].waitForExistence(timeout: 2)
        )
        app.terminate()
        launch(fixture: "demo-completed", reset: false)
        XCTAssertTrue(
            app.staticTexts["onboarding-permission-focusProtection"].waitForExistence(timeout: 5)
        )
    }

    func testEachPermissionDenialStillReachesPlayableHome() {
        for denial in ["deny-focus", "deny-end", "deny-return"] {
            launch(fixture: "permissions", reset: true, permission: denial)
            app.buttons["onboarding-demo-upgrade"].tap()
            for _ in 0..<3 {
                XCTAssertTrue(
                    app.buttons["onboarding-permission-allow"].waitForExistence(timeout: 3)
                )
                app.buttons["onboarding-permission-allow"].tap()
            }
            XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["mine-home-start"].exists)
            app.terminate()
        }
    }

    func testFreshAndProgressedHomeUseOneMineControlScene() {
        launch(fixture: "home-fresh", reset: true)
        XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 5))
        // The single promise sentence became three reachable steps.
        XCTAssertTrue(app.otherElements["mine-home-step-equipment"].exists)
        XCTAssertTrue(app.staticTexts["mine-home-deep-lock-reason"].exists)
        app.terminate()

        launch(fixture: "home-progressed", reset: true)
        XCTAssertTrue(app.staticTexts["mine-home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["mine-home-plan-safe"].isSelected)
        XCTAssertTrue(app.buttons["mine-home-start"].exists)
    }

    func testDeepPlanIsLockedThenUnlocked() {
        launch(fixture: "home-fresh", reset: true)
        let locked = app.buttons["mine-home-plan-deep"]
        XCTAssertTrue(locked.waitForExistence(timeout: 5))
        XCTAssertFalse(locked.isEnabled)
        XCTAssertTrue(app.staticTexts["mine-home-deep-lock-reason"].exists)
        app.terminate()

        launch(fixture: "home-unlocked", reset: true)
        let unlocked = app.buttons["mine-home-plan-deep"]
        XCTAssertTrue(unlocked.waitForExistence(timeout: 5))
        XCTAssertTrue(unlocked.isEnabled)
        unlocked.tap()
        XCTAssertTrue(unlocked.isSelected)
    }

    func testPlanAndDurationSelectionPersistAcrossRelaunch() {
        let storeID = "selection-\(UUID().uuidString)"
        launch(fixture: "home-unlocked", reset: true, storeID: storeID)
        app.buttons["mine-home-plan-deep"].tap()
        let duration = app.buttons["mine-home-duration-50"]
        if !duration.isHittable { app.swipeUp() }
        duration.tap()
        XCTAssertTrue(app.buttons["mine-home-plan-deep"].isSelected)
        XCTAssertTrue(duration.isSelected)
        app.terminate()

        launch(fixture: "home-unlocked", reset: false, storeID: storeID)
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
}
