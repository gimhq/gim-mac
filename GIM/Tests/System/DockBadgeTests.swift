import XCTest

@testable import GIM

final class DockBadgeTests: XCTestCase {
    func testLabel() {
        XCTAssertNil(DockBadge.label(count: 0, enabled: true))
        XCTAssertNil(DockBadge.label(count: 5, enabled: false))
        XCTAssertEqual(DockBadge.label(count: 1, enabled: true), "1")
        XCTAssertEqual(DockBadge.label(count: 999, enabled: true), "999")
        XCTAssertEqual(DockBadge.label(count: 1_000, enabled: true), "999+")
    }
}
