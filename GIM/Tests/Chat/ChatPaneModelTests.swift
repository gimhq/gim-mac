import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

/// `ChatPaneModel` on the demo client: the first window, older pages, read marks and the message actions.
@MainActor
final class ChatPaneModelTests: XCTestCase {
    /// An own, edited text message in the first window of "chat-sofia".
    private let ownMessageId = "msg-sofia-147"
    /// A text message from Sofia in the first window.
    private let otherMessageId = "msg-sofia-148"

    /// A started pane on the demo direct chat, once its messages and title arrived.
    private func makePane() async throws -> ChatPaneModel {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Alex")
        let client = try XCTUnwrap(model.client)
        let mediaDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-tests-media-\(UUID().uuidString)", isDirectory: true).path
        let pane = ChatPaneModel(
            client: client, chatId: "chat-sofia", ownUserId: model.session?.userId, mediaDirectory: mediaDirectory)
        pane.start()
        await waitUntil { Self.messageRowCount(pane) > 0 && !pane.timeline.title.isEmpty }
        return pane
    }

    private static func messageRowCount(_ pane: ChatPaneModel) -> Int {
        pane.timeline.items.filter { $0.messageRow != nil }.count
    }

    /// Yields, then sleeps briefly, until `condition` holds or about two seconds passed.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 {
            if condition() { return }
            await Task.yield()
        }
        for _ in 0..<100 {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func testFirstWindowAndTitle() async throws {
        let pane = try await makePane()
        XCTAssertGreaterThanOrEqual(Self.messageRowCount(pane), 40)
        XCTAssertEqual(pane.title, "Sofia Marin")
    }

    func testLoadOlderAddsMessages() async throws {
        let pane = try await makePane()
        let before = Self.messageRowCount(pane)
        await pane.timeline.loadOlder()
        await waitUntil { Self.messageRowCount(pane) > before }
        XCTAssertGreaterThan(Self.messageRowCount(pane), before)
    }

    func testMarkReadWhenBottomVisible() async throws {
        let pane = try await makePane()
        pane.isBottomVisible = true
        await pane.markReadIfNeeded()
        XCTAssertNotNil(pane.timeline.markedReadUpTo)
    }

    func testMarkReadSkippedWhenBottomHidden() async throws {
        let pane = try await makePane()
        pane.isBottomVisible = false
        await pane.markReadIfNeeded()
        XCTAssertNil(pane.timeline.markedReadUpTo)
    }

    func testReplySetsReplyTarget() async throws {
        let pane = try await makePane()
        pane.reply(to: otherMessageId)
        XCTAssertEqual(pane.composer.replyTarget?.messageId, otherMessageId)
    }

    func testEditOnlyOwnTextMessages() async throws {
        let pane = try await makePane()
        pane.edit(messageId: otherMessageId)
        XCTAssertNil(pane.composer.editTarget)
        pane.edit(messageId: ownMessageId)
        XCTAssertEqual(pane.composer.editTarget?.messageId, ownMessageId)
    }

    func testRequestDeleteOnlyOwnMessages() async throws {
        let pane = try await makePane()
        pane.requestDelete(messageId: otherMessageId)
        XCTAssertNil(pane.actions.pendingDelete)
        pane.requestDelete(messageId: ownMessageId)
        XCTAssertEqual(pane.actions.pendingDelete?.messageId, ownMessageId)
        pane.cancelDelete()
        XCTAssertNil(pane.actions.pendingDelete)
    }
}
