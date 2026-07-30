import Foundation
import XCTest

final class ProjectMembershipTests: XCTestCase {
    func testProductionWidgetExcludesAppOwnedSwiftDataWriter() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let project = try String(
            contentsOf: root.appending(path: "project.yml"),
            encoding: .utf8
        )
        let widgetStart = try XCTUnwrap(project.range(of: "  DeepMineProbeWidget:"))
        let widgetTail = project[widgetStart.lowerBound...]
        let monitorStart = try XCTUnwrap(
            widgetTail.range(of: "  DeepMineDeviceActivityMonitor:")
        )
        let widgetTarget = String(widgetTail[..<monitorStart.lowerBound])

        XCTAssertTrue(widgetTarget.contains("- ProbeSharedWrite.swift"))
        XCTAssertTrue(widgetTarget.contains("- ProbeDiagnosticIntents.swift"))
        XCTAssertTrue(widgetTarget.contains("- ProbeCommandWidget.swift"))
    }
}
