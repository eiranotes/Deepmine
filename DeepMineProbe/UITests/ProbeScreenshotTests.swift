import XCTest

@MainActor
final class ProbeScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCaptureDashboardSections() {
        launchAndCapture(
            section: "overview",
            identifier: "capture-overview",
            name: "01-overview"
        )
        launchAndCapture(
            section: "surfaces",
            identifier: "capture-surfaces",
            name: "02-return-signal"
        )
        launchAndCapture(
            section: "lock-gate",
            identifier: "capture-lock-gate",
            name: "03-mine-gate"
        )
        launchAndCapture(
            section: "integrity",
            identifier: "capture-integrity",
            name: "04-time-and-supplies"
        )
        launchAndCapture(
            section: "telemetry",
            identifier: "capture-telemetry",
            name: "05-mining-journal"
        )
        launchAndCapture(
            section: "device-gate",
            identifier: "capture-device-gate",
            name: "06-device-gate"
        )
        launchAndCapture(
            section: "lock-screen",
            identifier: "capture-lock-screen",
            name: "09-lock-screen-live-activity"
        )
    }

    func testCaptureDynamicIsland() {
        app = XCUIApplication()
        configureProbeLaunch(section: "surfaces")
        app.launch()

        let startButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "잠금화면 표지 켜기")
        ).firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        sleep(2)

        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 5))
        sleep(2)
        captureScreen(named: "07-dynamic-island-compact")

        let island = springboard.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.045)
        )
        island.press(forDuration: 1.2)
        sleep(1)
        captureScreen(named: "08-dynamic-island-expanded")
    }

    private func launchAndCapture(section: String, identifier: String, name: String) {
        app = XCUIApplication()
        configureProbeLaunch(section: section)
        app.launch()
        let sectionElement = app.otherElements[identifier]
        XCTAssertTrue(sectionElement.waitForExistence(timeout: 5))
        capture(sectionElement, named: name)
        app.terminate()
    }

    private func capture(_ element: XCUIElement, named name: String) {
        let attachment = XCTAttachment(screenshot: element.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func captureScreen(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func configureProbeLaunch(section: String) {
        app.launchEnvironment["DEEPMINE_SCREENSHOT_SECTION"] = section
        app.launchEnvironment["DEEPMINE_UI_FIXTURE"] = "diagnostics"
        app.launchEnvironment["DEEPMINE_UI_RESET"] = "1"
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = "\(name)-\(section)"
    }
}
