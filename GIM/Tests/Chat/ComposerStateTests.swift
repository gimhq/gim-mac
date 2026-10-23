import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

/// The composer through `ChatPaneModel` on the demo client: sending, replying to the selection and editing the last
/// own message.
@MainActor
final class ComposerStateTests: XCTestCase {
    /// A text message from Sofia in the first window of "chat-sofia".
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
        await waitUntil { !Self.messages(pane).isEmpty && !pane.timeline.title.isEmpty }
        return pane
    }

    private static func messages(_ pane: ChatPaneModel) -> [MessageItem] {
        pane.timeline.items.compactMap { $0.messageRow?.message }
    }

    private static func body(of message: MessageItem?) -> String? {
        guard case .text(let body)? = message?.content else { return nil }
        return body
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

    func testSendAppendsOwnMessageAndClearsText() async throws {
        let pane = try await makePane()
        pane.composer.textChanged("hi")
        await pane.send()
        await waitUntil { Self.body(of: Self.messages(pane).last) == "hi" }
        let last = try XCTUnwrap(Self.messages(pane).last)
        XCTAssertEqual(Self.body(of: last), "hi")
        XCTAssertTrue(last.isOwn)
        XCTAssertEqual(pane.composer.text, "")
    }

    func testReplyToSelectedSendsReply() async throws {
        let pane = try await makePane()
        pane.selectedMessageId = otherMessageId
        pane.replyToSelected()
        XCTAssertEqual(pane.composer.replyTarget?.messageId, otherMessageId)
        pane.composer.textChanged("sure")
        await pane.send()
        XCTAssertNil(pane.composer.replyTarget)
        await waitUntil { Self.body(of: Self.messages(pane).last) == "sure" }
        let last = try XCTUnwrap(Self.messages(pane).last)
        XCTAssertEqual(Self.body(of: last), "sure")
        XCTAssertEqual(last.replyTo?.messageId, otherMessageId)
    }

    func testReplyToSelectedWithoutSelectionDoesNothing() async throws {
        let pane = try await makePane()
        pane.replyToSelected()
        XCTAssertNil(pane.composer.replyTarget)
    }

    func testEditLastOwnMessage() async throws {
        let pane = try await makePane()
        let newestOwn = try XCTUnwrap(
            Self.messages(pane).last { $0.isOwn && Self.body(of: $0) != nil })
        pane.editLastOwnMessage()
        XCTAssertEqual(pane.composer.editTarget?.messageId, newestOwn.messageId)
        pane.composer.textChanged("changed")
        await pane.send()
        XCTAssertNil(pane.composer.editTarget)
        await waitUntil { Self.body(of: pane.timeline.message(withId: newestOwn.messageId)) == "changed" }
        let edited = try XCTUnwrap(pane.timeline.message(withId: newestOwn.messageId))
        XCTAssertEqual(Self.body(of: edited), "changed")
        XCTAssertTrue(edited.edited)
    }

    func testSendRequestsComposerFocus() async throws {
        let pane = try await makePane()
        let before = pane.composerFocusRequest
        pane.composer.textChanged("hello")
        await pane.send()
        XCTAssertGreaterThan(pane.composerFocusRequest, before)
    }
}
