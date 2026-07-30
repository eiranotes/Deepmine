import XCTest

@MainActor
final class GameWidgetSurfaceTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSmallAndMediumWidgetsRenderEveryGameState() {
        let states = ["waiting", "mining", "completed", "vein", "collapsed", "stale", "missing"]
        for language in ["ko", "en"] {
            for surface in ["small", "medium"] {
                for state in states {
                    launch(state: state, surface: surface, language: language)
                    let root = element("widget-\(surface)-\(state)")
                    XCTAssertTrue(
                        root.waitForExistence(timeout: 5),
                        "Missing \(language) \(state) on \(surface) widget"
                    )
                    let title = element("widget-status-title-\(state)")
                    XCTAssertTrue(title.exists, "Missing visible state title")
                    assert(title, isInside: root)
                    XCTAssertFalse(title.label.isEmpty)
                    app.terminate()
                }
            }
        }
    }

    func testWidgetActionsAndResultsStayTruthful() {
        launch(state: "waiting", surface: "small", language: "ko")
        let start = element("widget-start")
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(start.frame.height, 44)
        app.terminate()

        launch(state: "mining", surface: "medium", language: "ko")
        XCTAssertTrue(element("widget-open").waitForExistence(timeout: 5))
        XCTAssertFalse(matchingLabel("획득 광석").exists)
        XCTAssertFalse(matchingLabel("수정 광맥").exists)
        app.terminate()

        launch(state: "vein", surface: "medium", language: "ko")
        XCTAssertTrue(matchingLabel("수정 광맥").waitForExistence(timeout: 5))
        XCTAssertTrue(matchingLabel("획득 광석 1.2만").waitForExistence(timeout: 5))
    }

    func testMissingAndStaleWidgetsRequireAppRecovery() {
        for state in ["missing", "stale"] {
            launch(state: state, surface: "medium", language: "ko")
            XCTAssertTrue(element("widget-medium-\(state)").waitForExistence(timeout: 5))
            XCTAssertTrue(element("widget-open").exists)
            XCTAssertFalse(element("widget-start").exists)
            XCTAssertTrue(matchingLabel("앱에서 복구").exists)
            XCTAssertFalse(matchingLabel("0m").exists)
            XCTAssertFalse(element("widget-progress").exists)
            app.terminate()
        }
    }

    func testControlReflectsStateAndUsesOneSafeAction() {
        for state in ["waiting", "mining", "completed", "vein", "collapsed", "stale", "missing"] {
            launch(state: state, surface: "control", language: "ko")
            XCTAssertTrue(element("control-fixture-\(state)").waitForExistence(timeout: 5))
            let action = element("control-action")
            XCTAssertTrue(action.exists)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            app.terminate()
        }
    }

    func testEnglishWidgetAndControlCopyFitsDefaultSpec() {
        launch(state: "waiting", surface: "small", language: "en")
        let start = element("widget-start")
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.label.contains("Start a 25-minute safe mine"), start.label)
        app.terminate()
        launch(state: "mining", surface: "medium", language: "en")
        XCTAssertTrue(matchingLabel("20 minutes remaining").waitForExistence(timeout: 5))
        app.terminate()
        launch(state: "stale", surface: "control", language: "en")
        let recovery = element("control-action")
        XCTAssertTrue(recovery.waitForExistence(timeout: 5))
        XCTAssertTrue(recovery.label.contains("Open the app to recover"), recovery.label)
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
        app.launchEnvironment["DEEPMINE_UI_FIXTURE"] = "widget-\(state)"
        app.launchEnvironment["DEEPMINE_WIDGET_SURFACE"] = surface
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

    private func assert(
        _ child: XCUIElement,
        isInside parent: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let inset = parent.frame.insetBy(dx: -1, dy: -1)
        XCTAssertTrue(inset.contains(child.frame), "\(child.frame) outside \(parent.frame)", file: file, line: line)
    }
}
