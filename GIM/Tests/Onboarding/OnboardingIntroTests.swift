import XCTest

@testable import GIM

final class OnboardingIntroTests: XCTestCase {
    func testThreePages() {
        XCTAssertEqual(OnboardingIntroPages.pages.count, 3)
    }

    func testPagesCoverTheTitledSectionsInOrder() {
        XCTAssertEqual(
            OnboardingIntroPages.pages.flatMap { $0 },
            ["noPhoneNumber", "onYourDevices", "lockedMessages", "accountId", "recoveryKey"])
    }

    func testEverySectionResolvesToAnExplainerSection() {
        for page in OnboardingIntroPages.pages.indices {
            let sections = OnboardingIntroPages.sections(for: page)
            XCTAssertEqual(sections.map(\.id), OnboardingIntroPages.pages[page], "page \(page)")
            for section in sections {
                XCTAssertTrue(ExplainerContent.sections.contains(where: { $0.id == section.id }), section.id)
            }
        }
    }
}
