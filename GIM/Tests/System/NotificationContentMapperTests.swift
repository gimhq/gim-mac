import GIMClientKit
import XCTest

@testable import GIM

final class NotificationContentMapperTests: XCTestCase {
    private func event(kind: ChatKind, chat: String, sender: String) -> NewMessageEvent {
        NewMessageEvent(chatId: "chat-1", chatTitle: chat, kind: kind, senderName: sender, text: "Photo", sentAtMs: 1)
    }

    func testDirectChatUsesChatTitle() {
        let content = NotificationContentMapper.content(
            for: event(kind: .direct, chat: "Sofia Marin", sender: "Sofia Marin"))
        XCTAssertEqual(
            content,
            LocalNotificationContent(title: "Sofia Marin", body: "Photo", threadIdentifier: "chat-1", chatId: "chat-1"))
    }

    func testGroupChatNamesSender() {
        let content = NotificationContentMapper.content(
            for: event(kind: .group, chat: "Aegean Crew", sender: "Sofia Marin"))
        XCTAssertEqual(content.title, "Sofia Marin in Aegean Crew")
        XCTAssertEqual(content.body, "Photo")
        XCTAssertEqual(content.threadIdentifier, "chat-1")
    }

    func testGroupChatWithSenderNamedLikeChatUsesChatTitle() {
        let content = NotificationContentMapper.content(for: event(kind: .group, chat: "Crew", sender: "Crew"))
        XCTAssertEqual(content.title, "Crew")
    }

    func testMissingChatTitleUsesSender() {
        let content = NotificationContentMapper.content(for: event(kind: .group, chat: "", sender: "Sofia Marin"))
        XCTAssertEqual(content.title, "Sofia Marin")
    }
}
