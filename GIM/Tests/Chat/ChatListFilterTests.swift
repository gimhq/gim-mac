import XCTest

@testable import GIM

final class ChatListFilterTests: XCTestCase {
    func testEmptyQueryMatchesEverything() {
        XCTAssertTrue(ChatListFilter.matches(title: "Sofia Marin", subtitle: nil, query: ""))
        XCTAssertTrue(ChatListFilter.matches(title: "Sofia Marin", subtitle: nil, query: "   "))
    }

    func testMatchingIgnoresCase() {
        XCTAssertTrue(ChatListFilter.matches(title: "Sofia Marin", subtitle: nil, query: "sofia"))
    }

    func testMatchingIgnoresDiacritics() {
        XCTAssertTrue(ChatListFilter.matches(title: "Sofia Marín", subtitle: nil, query: "marin"))
    }

    func testEveryWordMustMatchTitleOrSubtitle() {
        XCTAssertTrue(ChatListFilter.matches(title: "Aegean Crew", subtitle: nil, query: "aegean crew"))
        XCTAssertTrue(
            ChatListFilter.matches(title: "Aegean Crew", subtitle: "Sofia: Weather window…", query: "crew sofia"))
    }

    func testMissingWordDoesNotMatch() {
        XCTAssertFalse(
            ChatListFilter.matches(title: "Aegean Crew", subtitle: "Sofia: Weather window…", query: "crew nikos"))
    }

    func testNormalizedCollapsesWhitespace() {
        XCTAssertEqual(ChatListFilter.normalized("  Sofía \n  Marin "), "sofia marin")
    }
}
