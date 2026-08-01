import XCTest

@MainActor
final class SettingsPrestigeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testThemeSelectionShowsLockedDepthAndPersistsUnlockedChoice() {
        launch("theme-locked")
        openSettings()
        open("settings-open-themes")
        XCTAssertTrue(element("theme-locked-crystal").label.contains("240m"))
        XCTAssertFalse(element("theme-select-crystal").isEnabled)
        app.terminate()

        let storeID = "theme-unlocked-\(UUID().uuidString)"
        launch("theme-unlocked", storeID: storeID)
        openSettings()
        open("settings-open-themes")
        open("theme-select-ruins")
        XCTAssertTrue(element("theme-selected-ruins").waitForExistence(timeout: 3))
        app.terminate()

        launch("theme-unlocked", reset: false, storeID: storeID)
        openSettings()
        open("settings-open-themes")
        XCTAssertTrue(reveal("theme-selected-ruins").waitForExistence(timeout: 3))
    }


    func testPermissionFailureCanRetryAndBlockListCanBeSaved() {
        launch("settings-needs-list")
        openSettings()
        XCTAssertTrue(element("settings-permission-focus-needs-selection").waitForExistence(timeout: 3))
        open("settings-permission-focus-choose-list")
        open("settings-block-list-save")
        XCTAssertTrue(element("settings-block-list-ready").waitForExistence(timeout: 3))
        app.terminate()

        launch("settings-denied")
        openSettings()
        XCTAssertTrue(element("settings-permission-focus-denied").waitForExistence(timeout: 3))
        open("settings-permission-focus-retry")
        XCTAssertTrue(element("settings-permission-focus-ready").waitForExistence(timeout: 3))
        open("settings-block-list-open")
        open("settings-block-list-save")
        XCTAssertTrue(element("settings-block-list-ready").waitForExistence(timeout: 3))
    }

    func testFeedbackPreferencesPersistAndRecoveryDoesNotExposeAPath() {
        let storeID = "feedback-off-\(UUID().uuidString)"
        launch("settings-feedback-off", storeID: storeID)
        openSettings()
        XCTAssertEqual(element("settings-haptics-toggle").value as? String, "0")
        XCTAssertEqual(element("settings-sound-toggle").value as? String, "0")
        element("settings-haptics-toggle").tap()
        XCTAssertEqual(element("settings-haptics-toggle").value as? String, "1")
        app.terminate()

        launch("settings-feedback-off", reset: false, storeID: storeID)
        openSettings()
        XCTAssertTrue(element("settings-haptics-toggle").waitForExistence(timeout: 3))
        XCTAssertEqual(element("settings-haptics-toggle").value as? String, "1")
        app.terminate()

        launch("settings-recovery")
        openSettings()
        let recovery = element("settings-recovery-notice")
        XCTAssertTrue(recovery.waitForExistence(timeout: 3))
        XCTAssertFalse(recovery.label.contains("/"))
    }

    func testDiagnosticsAreHiddenUntilSevenVersionTaps() {
        launch("settings-ready")
        openSettings()
        XCTAssertFalse(element("settings-open-diagnostics").exists)
        let version = element("settings-version")
        open("settings-version")
        for _ in 0..<6 { version.tap() }
        XCTAssertTrue(element("settings-open-diagnostics").waitForExistence(timeout: 3))
    }

    func testPrestigeRequiresLossConfirmationThenOffersShardAllocation() {
        launch("prestige-ineligible")
        openSettings()
        open("settings-open-prestige")
        XCTAssertTrue(element("prestige-ineligible").waitForExistence(timeout: 3))
        XCTAssertFalse(element("prestige-open-confirmation").isEnabled)
        app.terminate()

        launch("prestige-ready")
        openSettings()
        open("settings-open-prestige")
        XCTAssertTrue(
            element("prestige-preview").waitForExistence(timeout: 3),
            app.debugDescription
        )
        open("prestige-open-confirmation")
        XCTAssertTrue(element("prestige-losses").waitForExistence(timeout: 3))
        element("prestige-cancel").tap()
        XCTAssertTrue(element("prestige-preview").waitForExistence(timeout: 3))
        open("prestige-open-confirmation")
        open("prestige-confirm")
        XCTAssertTrue(element("prestige-allocation").waitForExistence(timeout: 3))
        open("prestige-upgrade-excavationMemory")
        XCTAssertTrue(element("prestige-upgrade-success").waitForExistence(timeout: 3))
        open("prestige-finish")
        XCTAssertTrue(element("mine-home-screen").waitForExistence(timeout: 3))
    }

    private func openSettings() {
        open("mine-home-settings")
        let screen = element("settings-screen")
        if !screen.waitForExistence(timeout: 3), element("mine-home-settings").isHittable {
            element("mine-home-settings").tap()
        }
        XCTAssertTrue(screen.waitForExistence(timeout: 5))
    }

    private func open(_ identifier: String) {
        let target = reveal(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        XCTAssertTrue(target.isHittable)
        target.tap()
    }

    private func reveal(_ identifier: String) -> XCUIElement {
        let target = element(identifier)
        for _ in 0..<5 where !target.exists || !target.isHittable { app.swipeUp() }
        return target
    }

    private func launch(_ fixture: String, reset: Bool = true, storeID: String? = nil) {
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
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
