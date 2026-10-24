import XCTest

@testable import GIM

final class AppVersionInfoTests: XCTestCase {
    func testReadsVersionAndBuild() {
        let info = AppVersionInfo.from(["CFBundleShortVersionString": "0.1.0", "CFBundleVersion": "7"])
        XCTAssertEqual(info, AppVersionInfo(version: "0.1.0", build: "7"))
    }

    func testMissingValuesAreQuestionMarks() {
        XCTAssertEqual(AppVersionInfo.from([:]), AppVersionInfo(version: "?", build: "?"))
    }
}
