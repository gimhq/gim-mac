import GIMClientKit
import XCTest

@testable import GIM

final class UnreadTrackerTests: XCTestCase {
    private func chat(
        _ id: String, kind: ChatKind = .direct, name: String, unread: UInt32 = 0, state: ChatState = .active,
        last: MessagePreview? = nil
    ) -> ChatSummary {
        ChatSummary(
            chatId: id, kind: kind, name: name, avatar: nil, lastMessage: last, unreadCount: unread,
            updatedAtMs: last?.sentAtMs ?? 0, memberCount: 2, state: state)
    }

    private func message(from sender: String, _ text: String, at ms: UInt64, own: Bool = false) -> MessagePreview {
        MessagePreview(senderName: sender, text: text, sentAtMs: ms, isOwn: own)
    }

    private func seededLedger() -> UnreadLedger {
        var ledger = UnreadLedger()
        let events = ledger.apply([
            .reset(values: [
                chat("direct", name: "Sofia Marin", unread: 1, last: message(from: "Sofia Marin", "Hi", at: 100)),
                chat("group", kind: .group, name: "Aegean Crew", last: message(from: "Alex Morgan", "Yo", at: 90)),
            ])
        ])
        XCTAssertEqual(events, [])
        return ledger
    }

    func testResetOnlySeeds() {
        let ledger = seededLedger()
        XCTAssertEqual(ledger.chats.map(\.chatId), ["direct", "group"])
    }

    func testNewerPeerMessageEmitsOneEvent() {
        var ledger = seededLedger()
        let events = ledger.apply([
            .set(
                index: 1,
                value: chat(
                    "group", kind: .group, name: "Aegean Crew", unread: 1,
                    last: message(from: "Sofia Marin", "Boat at 9", at: 200)))
        ])
        XCTAssertEqual(
            events,
            [
                NewMessageEvent(
                    chatId: "group", chatTitle: "Aegean Crew", kind: .group, senderName: "Sofia Marin",
                    text: "Boat at 9", sentAtMs: 200)
            ])

        // The same message again (a read receipt, say) is not new.
        let again = ledger.apply([
            .set(
                index: 1,
                value: chat(
                    "group", kind: .group, name: "Aegean Crew",
                    last: message(from: "Sofia Marin", "Boat at 9", at: 200)))
        ])
        XCTAssertEqual(again, [])
    }

    func testOwnMessageEmitsNothing() {
        var ledger = seededLedger()
        let events = ledger.apply([
            .set(
                index: 0,
                value: chat(
                    "direct", name: "Sofia Marin", last: message(from: "Alex Morgan", "Hey", at: 300, own: true)))
        ])
        XCTAssertEqual(events, [])
    }

    func testNewChatAfterSeedEmitsEvent() {
        var ledger = seededLedger()
        let events = ledger.apply([
            .pushFront(value: chat("new", name: "Noah", unread: 1, last: message(from: "Noah", "Hello", at: 50)))
        ])
        XCTAssertEqual(events.map(\.chatId), ["new"])
        XCTAssertEqual(ledger.chats.map(\.chatId), ["new", "direct", "group"])
    }

    func testTotalUnreadCountsActiveChatsOnly() {
        var ledger = UnreadLedger()
        _ = ledger.apply([
            .reset(values: [
                chat("a", name: "A", unread: 3),
                chat("b", name: "B", unread: 2, state: .left),
                chat("c", name: "C", unread: 4),
                chat("d", name: "D", unread: 7, state: .leaving),
            ])
        ])
        XCTAssertEqual(ledger.totalUnread, 7)
    }

    func testInvalidBatchIsDroppedAndNextBatchSeeds() {
        var ledger = seededLedger()
        XCTAssertEqual(ledger.apply([.remove(index: 9)]), [])
        XCTAssertTrue(ledger.isOutOfSync)
        XCTAssertEqual(ledger.chats.count, 2)

        let events = ledger.apply([
            .reset(values: [chat("direct", name: "Sofia Marin", last: message(from: "Sofia Marin", "Later", at: 400))])
        ])
        XCTAssertEqual(events, [])
        XCTAssertFalse(ledger.isOutOfSync)
    }

    @MainActor
    func testTrackerReportsIncomingMessageFromClient() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-tests-\(UUID().uuidString)", isDirectory: true)
        let client = FakeGimClient.demo(
            scheduler: ImmediateFakeScheduler(), dataDirectory: directory.path, registered: true)
        let tracker = UnreadTracker()
        var events: [NewMessageEvent] = []
        tracker.onNewMessage = { events.append($0) }
        tracker.attach(client)
        defer { tracker.detach() }

        try await waitUntil { tracker.chats.count >= 2 }
        XCTAssertEqual(events, [])

        try await client.receiveText(chatId: FakeGimClient.demoDirectChatId, from: "user-sofia", body: "Are you there?")
        try await waitUntil { !events.isEmpty }
        XCTAssertEqual(events.first?.chatId, FakeGimClient.demoDirectChatId)
        XCTAssertEqual(events.first?.text, "Are you there?")
        XCTAssertEqual(events.first?.senderName, "Sofia Marin")
        XCTAssertGreaterThan(tracker.totalUnread, 0)

        tracker.detach()
        XCTAssertEqual(tracker.chats, [])
        XCTAssertEqual(tracker.totalUnread, 0)
    }

    @MainActor
    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(2)
        while !condition(), ContinuousClock.now < deadline {
            await Task.yield()
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertTrue(condition())
    }
}
