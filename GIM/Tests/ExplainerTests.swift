import XCTest

@testable import GIM

final class ExplainerTests: XCTestCase {
    func testSixSectionsInOrder() {
        XCTAssertEqual(ExplainerContent.sections.count, 6)
        XCTAssertEqual(
            ExplainerContent.sections.map(\.id),
            ["intro", "noPhoneNumber", "onYourDevices", "lockedMessages", "accountId", "recoveryKey"])
    }

    func testIdsAreUnique() {
        let ids = ExplainerContent.sections.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testIntroHasBodyOnly() throws {
        let intro = try XCTUnwrap(ExplainerContent.sections.first)
        XCTAssertNil(intro.titleKey)
        XCTAssertNil(intro.title())
        XCTAssertFalse(intro.body().isEmpty)
    }

    func testOtherSectionsHaveTitleAndBody() {
        for section in ExplainerContent.sections.dropFirst() {
            XCTAssertNotNil(section.titleKey, section.id)
            XCTAssertFalse(section.title()?.isEmpty ?? true, section.id)
            XCTAssertFalse(section.body().isEmpty, section.id)
        }
    }

    /// The test host is the app, so `Bundle.main` carries the compiled `Explainer` table; a key that did not resolve
    /// comes back unchanged.
    func testStringsResolveThroughTheCatalog() {
        let title = String(localized: ExplainerContent.title, table: "Explainer")
        XCTAssertNotEqual(title, "explainer.title")
        XCTAssertEqual(title, "How gim works")
        for section in ExplainerContent.sections {
            XCTAssertFalse(section.body().hasPrefix("explainer."), section.id)
            if let title = section.title() {
                XCTAssertFalse(title.hasPrefix("explainer."), section.id)
            }
        }
    }
}
