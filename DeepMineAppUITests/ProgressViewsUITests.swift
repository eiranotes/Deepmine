import XCTest

@MainActor
final class ProgressViewsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testHomeRoutesToAllThreeProgressLedgers() {
        assertRoute(button: "mine-home-equipment", fixture: "progress-populated", screen: "equipment-screen")
        assertRoute(button: "mine-home-journal", fixture: "progress-populated", screen: "journal-screen")
        assertRoute(button: "mine-home-statistics", fixture: "progress-populated", screen: "statistics-screen")

        launch("return-normal")
        XCTAssertTrue(element("return-recommendation-affordable").waitForExistence(timeout: 6))
        element("return-prepare-next").tap()
        XCTAssertTrue(element("equipment-handoff-affordable").waitForExistence(timeout: 3))
        let kind = ["drill", "cart", "lamp"].first {
            element("equipment-recommendation-kind-\($0)").exists
        }
        XCTAssertNotNil(kind)
        open("equipment-upgrade-\(kind!)")
        XCTAssertTrue(element("equipment-notice-success").waitForExistence(timeout: 3))
        XCTAssertFalse(element("equipment-handoff-affordable").exists)
    }

    func testEquipmentPurchasePersistsAndShowsSuccess() {
        let storeID = "equipment-success-\(UUID().uuidString)"
        launch("equipment-success", storeID: storeID)
        open("mine-home-equipment")
        XCTAssertTrue(element("equipment-upgrade-drill").waitForExistence(timeout: 3))
        element("equipment-upgrade-drill").tap()
        XCTAssertTrue(element("equipment-notice-success").waitForExistence(timeout: 3))
        app.terminate()

        launch("equipment-success", reset: false, storeID: storeID)
        open("mine-home-equipment")
        XCTAssertTrue(element("equipment-level-drill").waitForExistence(timeout: 3))
        XCTAssertTrue(element("equipment-level-drill").label.contains("2"))
        app.terminate()

        launch("equipment-retry-ambiguous")
        open("mine-home-equipment")
        open("equipment-upgrade-drill")
        XCTAssertTrue(element("equipment-notice-error").waitForExistence(timeout: 3))
        element("equipment-retry").tap()
        XCTAssertTrue(element("equipment-notice-success").waitForExistence(timeout: 3))
        XCTAssertTrue(element("equipment-level-drill").label.contains("2"))
        XCTAssertTrue(element("equipment-ore").label.contains("400"))
    }

    func testEquipmentExplainsInsufficientOreAndMaximumLevel() {
        launch("equipment-insufficient")
        open("mine-home-equipment")
        element("equipment-upgrade-drill").tap()
        XCTAssertTrue(element("equipment-notice-insufficient").waitForExistence(timeout: 3))
        app.terminate()

        launch("equipment-maximum")
        open("mine-home-equipment")
        XCTAssertTrue(element("equipment-maximum-drill").waitForExistence(timeout: 3))
        XCTAssertFalse(element("equipment-upgrade-drill").isEnabled)
    }

    func testJournalHasPurposefulEmptyAndPopulatedStates() {
        launch("progress-empty")
        open("mine-home-journal")
        XCTAssertTrue(element("journal-empty").waitForExistence(timeout: 3))
        app.terminate()

        launch("progress-populated")
        open("mine-home-journal")
        XCTAssertTrue(element("journal-entry").waitForExistence(timeout: 3))
        XCTAssertTrue(element("journal-entry-abandoned").exists)
        XCTAssertTrue(reveal("journal-entry-completed").exists)
    }

    func testStatisticsReadAtZeroAndFiveHundredHistoryEntries() {
        launch("progress-empty")
        open("mine-home-statistics")
        XCTAssertTrue(element("statistics-zero").waitForExistence(timeout: 3))
        app.terminate()

        launch("progress-overflow")
        open("mine-home-statistics")
        XCTAssertTrue(element("statistics-total-sessions").waitForExistence(timeout: 3))
        let completions = element("statistics-total-sessions").label
        XCTAssertTrue(completions.contains("완료한 채굴"))
        XCTAssertTrue(completions.contains("428 / 500"))
        let focus = element("statistics-focus").label
        XCTAssertTrue(focus.contains("주간 집중"))
        XCTAssertTrue(focus.contains("1.3만") && focus.contains("분"))
        let depth = element("statistics-depth").label
        XCTAssertTrue(depth.contains("최고 귀환 심도"))
        XCTAssertTrue(depth.contains("1,607m"))
        XCTAssertTrue(element("statistics-ore").label.contains("귀환 광석"))
        XCTAssertTrue(element("statistics-plan-mix").exists)
        XCTAssertTrue(element("statistics-vein-history").exists)
        XCTAssertTrue(element("statistics-plan-safe").label.contains("안전 갱도 167"))
        XCTAssertTrue(element("statistics-plan-deep").label.contains("심층 갱도 167"))
        XCTAssertTrue(element("statistics-plan-survey").label.contains("탐사 갱도 166"))
        let vein = firstElement("statistics-vein-entry")
        XCTAssertTrue(vein.label.contains("2026"))
        XCTAssertTrue(vein.label.contains("광맥"))
    }

    func testRecoveryStateOffersRetry() {
        launch("progress-recovery")
        open("mine-home-equipment")
        XCTAssertTrue(element("equipment-notice-error").waitForExistence(timeout: 3))
        XCTAssertTrue(element("equipment-retry").isEnabled)
        element("equipment-retry").tap()
        let upgrade = element("equipment-upgrade-drill")
        expectation(
            for: NSPredicate(format: "exists == true AND enabled == true"),
            evaluatedWith: upgrade
        )
        waitForExpectations(timeout: 3)
        XCTAssertFalse(element("equipment-notice-error").exists)
    }

    func testEnglishMediumContentKeepsSemanticControls() {
        launch("equipment-success", language: "en")
        open("mine-home-equipment")
        let upgrade = element("equipment-upgrade-drill")
        XCTAssertTrue(upgrade.waitForExistence(timeout: 3))
        XCTAssertTrue(upgrade.label.contains("Drill"))
        XCTAssertTrue(upgrade.label.contains("Upgrade"))
        XCTAssertTrue(upgrade.label.contains("Ore"))
        app.terminate()

        launch("progress-populated", language: "en")
        open("mine-home-journal")
        XCTAssertTrue(element("journal-entry-abandoned").label.contains("Returned early"))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "minutes")
        ).firstMatch.exists)
        let completed = reveal("journal-entry-completed")
        XCTAssertTrue(completed.label.contains("Completed"))
        app.terminate()

        launch("progress-populated", language: "en")
        open("mine-home-statistics")
        XCTAssertTrue(element("statistics-screen").waitForExistence(timeout: 3))
        XCTAssertTrue(element("statistics-total-sessions").label.contains("Completed mines"))
        XCTAssertTrue(element("statistics-plan-mix").exists)
        XCTAssertTrue(element("statistics-vein-history").exists)
        XCTAssertTrue(app.navigationBars.firstMatch.buttons.firstMatch.exists)
    }

    private func assertRoute(button: String, fixture: String, screen: String) {
        launch(fixture)
        open(button)
        XCTAssertTrue(element(screen).waitForExistence(timeout: 3))
        app.terminate()
    }

    private func open(_ identifier: String) {
        let button = element(identifier)
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<3 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    private func reveal(_ identifier: String) -> XCUIElement {
        let target = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        for _ in 0..<4 where !target.exists { app.swipeUp() }
        XCTAssertTrue(target.waitForExistence(timeout: 3))
        return target
    }

    private func launch(
        _ fixture: String,
        reset: Bool = true,
        storeID: String? = nil,
        language: String = "ko"
    ) {
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "ko" ? "ko_KR" : "en_US",
            "-AppleInterfaceStyle", "Dark",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM"
        ]
        app.launchEnvironment["DEEPMINE_UI_FIXTURE"] = fixture
        app.launchEnvironment["DEEPMINE_UI_PERMISSION"] = "granted"
        app.launchEnvironment["DEEPMINE_UI_READINESS"] = "sealed"
        app.launchEnvironment["DEEPMINE_UI_RESET"] = reset ? "1" : "0"
        app.launchEnvironment["DEEPMINE_UI_STORE_ID"] = storeID ?? "\(name)-\(fixture)-\(language)"
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func firstElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
