import XCTest

@MainActor
final class GameFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testPracticeReturnLeadsIntoFirstPlayableMineAndEquipmentHandoff() {
        launch("demo-completed")
        let upgrade = app.buttons["onboarding-demo-upgrade"]
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5))
        upgrade.tap()
        for _ in 0..<3 {
            let allow = app.buttons["onboarding-permission-allow"]
            XCTAssertTrue(allow.waitForExistence(timeout: 4))
            allow.tap()
        }
        XCTAssertTrue(element("mine-home-screen").waitForExistence(timeout: 5))

        open("mine-home-start")
        XCTAssertTrue(element("preflight-selection").waitForExistence(timeout: 3))
        open("preflight-confirm-start")
        XCTAssertTrue(element("active-mine-header").waitForExistence(timeout: 6))

        open("active-mine-abandon")
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["중도 귀환 확인"].tap()
        XCTAssertTrue(element("return-report").waitForExistence(timeout: 6))
        XCTAssertTrue(element("return-ore-haul").waitForExistence(timeout: 6))
        XCTAssertTrue(element("return-beat-next").waitForExistence(timeout: 6))

        open("return-prepare-next")
        XCTAssertTrue(element("equipment-screen").waitForExistence(timeout: 4))
        XCTAssertTrue(element("equipment-recommendation").exists)
    }

    private func launch(_ fixture: String) {
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
        app.launchEnvironment["DEEPMINE_UI_RESET"] = "1"
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = "\(name)-\(fixture)"
        app.launch()
    }

    private func open(_ identifier: String) {
        let target = element(identifier)
        for _ in 0..<5 where !target.exists || !target.isHittable { app.swipeUp() }
        XCTAssertTrue(target.waitForExistence(timeout: 5), identifier)
        XCTAssertTrue(target.isHittable, identifier)
        target.tap()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
