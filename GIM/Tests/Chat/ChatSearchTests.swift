import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class ChatSearchTests: XCTestCase {
    private func row(_ id: String, _ body: MessageBody) -> TimelineDisplayItem {
        let message = MessageItem(
            messageId: id, chatId: "chat-test",
            sender: UserProfile(userId: "sofia", displayName: "Sofia"),
            isOwn: false, sentAtMs: 0, content: .text(body: ""), replyTo: nil, reactions: [],
            edited: false, sendState: nil)
        let row = TimelineMessageRow(
            message: message, body: body, senderName: nil, isFirstInRun: true, hasTail: true, reply: nil,
            reactions: [], isEdited: false, timeText: "09:00", status: nil)
        return TimelineDisplayItem(id: TimelineDisplayItem.id(forMessage: id), kind: .message(row))
    }

    private func media(_ id: String) -> MediaRef {
        MediaRef(chatId: "chat-test", messageId: id, mime: "image/jpeg", size: 1, hasThumbnail: false)
    }

    /// Three rows mention the crew: a text, an image caption and a file name; a deleted row and a day chip do not.
    private var items: [TimelineDisplayItem] {
        [
            TimelineDisplayItem(id: "day:1", kind: .dateSeparator("Today")),
            row("m1", .text("The crew meets at nine")),
            row("m2", .text("Weather looks fine")),
            row("m3", .image(media: media("m3"), width: 10, height: 10, caption: "Crew on deck")),
            row("m4", .placeholder("This message was deleted (crew)")),
            row("m5", .file(media: media("m5"), fileName: "crew-list.txt", sizeText: "1 KB", caption: nil)),
        ]
    }

    func testMatchIdsFindTextCaptionAndFileNameInOrder() {
        XCTAssertEqual(ChatSearch.matchIds(in: items, query: "CREW"), ["m1", "m3", "m5"])
        XCTAssertEqual(ChatSearch.matchIds(in: items, query: "list"), ["m5"])
        XCTAssertEqual(ChatSearch.matchIds(in: items, query: "  "), [])
    }

    func testUpdateStartsAtNewestAndNextWraps() {
        let search = ChatSearch()
        search.query = "crew"
        search.update(items: items)
        XCTAssertEqual(search.currentMatchId, "m5")
        search.next()
        XCTAssertEqual(search.currentMatchId, "m1")
    }

    func testPreviousWrapsFromFirstToLast() {
        let search = ChatSearch()
        search.query = "crew"
        search.update(items: items)
        search.next()
        XCTAssertEqual(search.currentMatchId, "m1")
        search.previous()
        XCTAssertEqual(search.currentMatchId, "m5")
    }

    func testCountText() {
        let search = ChatSearch()
        XCTAssertNil(search.countText)
        search.query = "crew"
        search.update(items: items)
        search.previous()
        XCTAssertEqual(search.countText, "2 of 3")
    }

    func testUpdateKeepsCurrentMatch() {
        let search = ChatSearch()
        search.query = "crew"
        search.update(items: items)
        search.previous()
        search.update(items: items)
        XCTAssertEqual(search.currentMatchId, "m3")
    }

    func testAbsentQueryHasNoMatches() {
        let search = ChatSearch()
        search.query = "crew"
        search.update(items: items)
        search.query = "harbour"
        search.update(items: items)
        XCTAssertEqual(search.countText, "No matches")
        XCTAssertNil(search.currentMatchId)
        XCTAssertEqual(search.matchIds, [])
    }

    func testCloseResetsEverything() {
        let search = ChatSearch()
        search.activate()
        search.query = "crew"
        search.update(items: items)
        search.close()
        XCTAssertFalse(search.isActive)
        XCTAssertEqual(search.query, "")
        XCTAssertEqual(search.matchIds, [])
        XCTAssertNil(search.currentIndex)
        XCTAssertNil(search.countText)
    }
}
