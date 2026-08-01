import XCTest

@MainActor
final class ActiveMineUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testHomeSelectionFlowsIntoPreflightTruthfully() {
        launch(fixture: "preflight-survey", readiness: "sealed")
        tapHomeStart()
        XCTAssertTrue(element("preflight-selection").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["탐사 갱도"].exists)
        XCTAssertTrue(app.staticTexts["50 분"].exists)
        XCTAssertTrue(element("preflight-reward-breakdown").exists)
    }

    func testOpenPreflightExplainsMultiplierAndRemainsPlayable() {
        launch(fixture: "preflight-open", readiness: "open")
        tapHomeStart()
        XCTAssertTrue(element("preflight-readiness-open").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "×0.75")
        ).firstMatch.exists)
        XCTAssertTrue(app.buttons["preflight-confirm-start"].isEnabled)
        XCTAssertTrue(app.buttons["preflight-configure"].exists)
    }

    func testConfirmStartTransitionsToQuietActiveMine() {
        launch(fixture: "preflight-sealed", readiness: "sealed")
        tapHomeStart()
        XCTAssertTrue(app.buttons["preflight-confirm-start"].waitForExistence(timeout: 3))
        app.buttons["preflight-confirm-start"].tap()
        XCTAssertTrue(element("preflight-preparing").waitForExistence(timeout: 2))
        XCTAssertTrue(element("active-mine-header").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["active-mine-timer"].exists)
        XCTAssertTrue(element("active-mine-quiet").exists)
        XCTAssertFalse(element("preflight-reward-breakdown").exists)
    }

    func testNoListReadinessFixture() {
        assertReadiness(fixture: "preflight-no-list", readiness: "noList")
    }

    func testPendingReadinessFixture() {
        assertReadiness(fixture: "preflight-pending", readiness: "pending")
    }

    func testFailureReadinessFixture() {
        assertReadiness(fixture: "preflight-failure", readiness: "failure")
    }

    func testActiveOpenGrade() {
        launch(fixture: "active-open", readiness: "open")
        XCTAssertTrue(element("active-mine-open").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "×0.75")
        ).firstMatch.exists)
    }

    func testActiveCollapsedGrade() {
        launch(fixture: "active-collapsed", readiness: "sealed")
        XCTAssertTrue(element("active-mine-collapsed").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "×0.5")
        ).firstMatch.exists)
    }

    func testAbandonRequiresConfirmationAndCancelIsNoOp() {
        launch(fixture: "active-safe", readiness: "sealed")
        XCTAssertTrue(app.buttons["active-mine-abandon"].waitForExistence(timeout: 5))
        app.buttons["active-mine-abandon"].tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        alert.buttons["채굴 계속"].tap()
        XCTAssertTrue(app.buttons["active-mine-abandon"].exists)
        XCTAssertFalse(element("return-report").exists)
    }

    func testSafePartialConsequence() {
        assertPartialConsequence(fixture: "active-safe")
    }

    func testSurveyPartialConsequence() {
        assertPartialConsequence(fixture: "active-survey")
    }

    func testDeepZeroConsequence() {
        launch(fixture: "active-deep", readiness: "sealed")
        app.buttons["active-mine-abandon"].tap()
        let deepAlert = app.alerts.firstMatch
        XCTAssertTrue(deepAlert.waitForExistence(timeout: 2))
        XCTAssertTrue(deepAlert.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "0")
        ).firstMatch.exists)
    }

    private func assertReadiness(fixture: String, readiness: String) {
        launch(fixture: fixture, readiness: readiness)
        tapHomeStart()
        XCTAssertTrue(element("preflight-readiness-\(readiness)").waitForExistence(timeout: 3))
    }

    private func assertPartialConsequence(fixture: String) {
        launch(fixture: fixture, readiness: "sealed")
        app.buttons["active-mine-abandon"].tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        XCTAssertTrue(alert.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "×0.5")
        ).firstMatch.exists)
    }

    func testConfirmedAbandonIsIdempotentAcrossRelaunch() {
        let storeID = "abandon-\(UUID().uuidString)"
        launch(fixture: "active-safe", readiness: "sealed", storeID: storeID)
        app.buttons["active-mine-abandon"].tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        alert.buttons["중도 귀환 확인"].tap()
        XCTAssertTrue(element("return-report").waitForExistence(timeout: 5))
        app.terminate()

        launch(
            fixture: "active-safe",
            readiness: "sealed",
            reset: false,
            storeID: storeID
        )
        XCTAssertTrue(element("return-report").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["active-mine-abandon"].exists)
    }

    private func launch(
        fixture: String,
        readiness: String,
        reset: Bool = true,
        storeID: String? = nil
    ) {
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleInterfaceStyle", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"
        ]
        app.launchEnvironment["DEEPMINE_UI_FIXTURE"] = fixture
        app.launchEnvironment["DEEPMINE_UI_READINESS"] = readiness
        app.launchEnvironment["DEEPMINE_UI_PERMISSION"] = "granted"
        app.launchEnvironment["DEEPMINE_UI_RESET"] = reset ? "1" : "0"
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = storeID ?? "\(name)-\(fixture)"
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func tapHomeStart() {
        let amplifier = app.buttons["mine-home-focus-amplifier"]
        for _ in 0..<10 where !amplifier.exists || !amplifier.isHittable { app.swipeUp() }
        XCTAssertTrue(amplifier.waitForExistence(timeout: 5), "mine-home-focus-amplifier")
        amplifier.tap()
        let start = app.buttons["mine-home-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "mine-home-start")
        for _ in 0..<10 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable, "mine-home-start")
        start.tap()
    }
}
