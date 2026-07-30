import XCTest

@MainActor
final class ReturnReportUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testNormalReturnUnfoldsThreeBeatsAndOffersEqualChoices() {
        launch("return-normal")
        XCTAssertTrue(element("return-beat-confirmation").waitForExistence(timeout: 5))
        XCTAssertTrue(element("return-beat-reward").waitForExistence(timeout: 3))
        XCTAssertTrue(element("return-beat-next").waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["return-finish"].exists)
        XCTAssertTrue(app.buttons["return-prepare-next"].exists)
    }

    func testNoVeinReturnStillFeelsComplete() {
        launch("return-no-vein")
        XCTAssertTrue(element("return-no-vein").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "광석")
        ).firstMatch.exists)
    }

    func testBlueVeinExplainsItsEffect() { assertVein("blue") }
    func testCrystalVeinExplainsItsEffect() { assertVein("crystal") }
    func testVaultVeinExplainsItsEffect() { assertVein("vault") }
    func testResonanceVeinExplainsItsEffect() { assertVein("resonance") }
    func testAbyssVeinExplainsItsEffect() { assertVein("abyss") }

    func testAbandonedReturnUsesTruthfulConfirmation() {
        launch("return-abandoned")
        XCTAssertTrue(element("return-outcome-abandoned").waitForExistence(timeout: 5))
        XCTAssertTrue(element("return-beat-reward").waitForExistence(timeout: 3))
    }

    func testCollapsedReturnDoesNotPresentSuccessGrade() {
        launch("return-collapsed")
        XCTAssertTrue(element("return-grade-collapsed").waitForExistence(timeout: 5))
        XCTAssertFalse(element("return-grade-sealed").exists)
    }

    func testUnaffordableRecommendationRoutesWithoutPurchasing() {
        launch("return-unaffordable")
        XCTAssertTrue(element("return-recommendation-unaffordable").waitForExistence(timeout: 6))
        app.buttons["return-prepare-next"].tap()
        XCTAssertTrue(element("equipment-screen").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "광석과 장비는 그대로")
        ).firstMatch.waitForExistence(timeout: 2))
    }

    func testFinishDismissalSurvivesRelaunch() {
        let storeID = "return-finish-\(UUID().uuidString)"
        launch("return-normal", storeID: storeID)
        XCTAssertTrue(app.buttons["return-finish"].waitForExistence(timeout: 6))
        app.buttons["return-finish"].tap()
        XCTAssertTrue(element("mine-home").waitForExistence(timeout: 3))
        app.terminate()

        launch("return-normal", reset: false, storeID: storeID)
        XCTAssertTrue(element("mine-home").waitForExistence(timeout: 5))
        XCTAssertFalse(element("return-report").exists)
    }

    private func assertVein(_ kind: String) {
        launch("return-\(kind)")
        XCTAssertTrue(element("return-vein-\(kind)").waitForExistence(timeout: 5))
        XCTAssertTrue(element("return-vein-effect").exists)
    }

    private func launch(
        _ fixture: String,
        reset: Bool = true,
        storeID: String? = nil
    ) {
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(ko)",
            "-AppleLocale", "ko_KR",
            "-AppleInterfaceStyle", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"
        ]
        app.launchEnvironment["DEEPMINE_UI_FIXTURE"] = fixture
        app.launchEnvironment["DEEPMINE_UI_PERMISSION"] = "granted"
        app.launchEnvironment["DEEPMINE_UI_READINESS"] = "sealed"
        app.launchEnvironment["DEEPMINE_UI_RESET"] = reset ? "1" : "0"
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = storeID ?? "\(name)-\(fixture)"
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
