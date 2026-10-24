import XCTest

@testable import GIM

final class NotificationPolicyTests: XCTestCase {
    func testNotifiesWhenAppIsInBackground() {
        XCTAssertTrue(NotificationPolicy.shouldNotify(appIsActive: false, selectedChatId: "a", chatId: "a"))
    }

    func testNotifiesForAnotherChatWhileActive() {
        XCTAssertTrue(NotificationPolicy.shouldNotify(appIsActive: true, selectedChatId: "b", chatId: "a"))
        XCTAssertTrue(NotificationPolicy.shouldNotify(appIsActive: true, selectedChatId: nil, chatId: "a"))
    }

    func testSkipsTheChatOnScreen() {
        XCTAssertFalse(NotificationPolicy.shouldNotify(appIsActive: true, selectedChatId: "a", chatId: "a"))
    }
}
