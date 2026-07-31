import XCTest

@MainActor
final class GameSurfaceScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCaptureCoreLoopScreens() {
        launch("fresh")
        captureScreen(after: "onboarding-premise-blocks", named: "01-onboarding")

        launch("progress-populated")
        captureScreen(after: "mine-home-screen", named: "02-mine-home")

        launch("preflight-survey")
        let start = app.buttons["mine-home-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        for _ in 0..<5 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable, "mine-home-start")
        start.tap()
        captureScreen(after: "preflight-selection", named: "03-preflight")

        launch("active-sealed")
        captureScreen(after: "active-mine-header", named: "04-active-mine")

        launch("return-crystal")
        captureScreen(after: "return-beat-next", named: "05-return-report", timeout: 7)
    }

    func testCaptureProgressScreens() {
        launch("progress-populated")
        open("mine-home-equipment")
        captureScreen(after: "equipment-screen", named: "06-equipment")

        launch("progress-populated")

        launch("progress-populated")
        open("mine-home-statistics")
        captureScreen(after: "statistics-screen", named: "08-statistics")
    }

    func testCaptureSettingsScreens() {
        launch("theme-unlocked")
        openSettings()
        open("settings-open-themes")
        captureScreen(after: "theme-screen", named: "09-mine-themes")

        launch("settings-ready")
        openSettings()
        captureScreen(after: "settings-screen", named: "10-settings")

        launch("prestige-ready")
        openSettings()
        open("settings-open-prestige")
        open("prestige-open-confirmation")
        captureScreen(after: "prestige-losses", named: "11-deep-descent")
    }

    func testCaptureActivitySurfaces() {
        captureActivity(surface: "minimal", name: "12-activity-minimal")
        captureActivity(surface: "compact", name: "13-activity-compact")
        captureActivity(surface: "expanded", name: "14-activity-expanded")
        captureActivity(surface: "lock", name: "15-lock-screen")
        captureActivity(surface: "standby", name: "16-standby")
    }

    func testCaptureWidgetAndControlSurfaces() {
        captureWidget(
            state: "waiting", surface: "small",
            identifier: "widget-small-waiting", name: "17-widget-small"
        )
        captureWidget(
            state: "vein", surface: "medium",
            identifier: "widget-medium-vein", name: "18-widget-medium"
        )
        captureWidget(
            state: "mining", surface: "control",
            identifier: "control-fixture-mining", name: "19-control-center"
        )
    }

    private func captureActivity(surface: String, name: String) {
        launch("surface-mining", activitySurface: surface)
        captureElement("activity-\(surface)-mining", named: name)
    }

    private func captureWidget(
        state: String,
        surface: String,
        identifier: String,
        name: String
    ) {
        launch("widget-\(state)", widgetSurface: surface)
        captureElement(identifier, named: name)
    }

    private func openSettings() {
        open("mine-home-settings")
        XCTAssertTrue(element("settings-screen").waitForExistence(timeout: 15))
    }

    private func open(_ identifier: String) {
        let target = element(identifier)
        for _ in 0..<5 where !target.exists || !target.isHittable { app.swipeUp() }
        XCTAssertTrue(target.waitForExistence(timeout: 15), identifier)
        target.tap()
    }

    private func launch(
        _ fixture: String,
        activitySurface: String? = nil,
        widgetSurface: String? = nil
    ) {
        app?.terminate()
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
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = "\(name)-\(fixture)-\(activitySurface ?? widgetSurface ?? "app")"
        if let activitySurface {
            app.launchEnvironment["DEEPMINE_ACTIVITY_SURFACE"] = activitySurface
        }
        if let widgetSurface {
            app.launchEnvironment["DEEPMINE_WIDGET_SURFACE"] = widgetSurface
        }
        app.launch()
    }

    // Capturing walks two navigation pushes per screen. Five seconds is enough when
    // this class runs alone but times out under full-suite simulator load, which reads
    // as a defect instead of the scheduling delay it is.
    private func captureScreen(after identifier: String, named name: String, timeout: TimeInterval = 15) {
        XCTAssertTrue(element(identifier).waitForExistence(timeout: timeout), identifier)
        keep(XCUIScreen.main.screenshot(), named: name)
    }

    private func captureElement(_ identifier: String, named name: String) {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: 15), identifier)
        keep(target.screenshot(), named: name)
    }

    private func keep(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
