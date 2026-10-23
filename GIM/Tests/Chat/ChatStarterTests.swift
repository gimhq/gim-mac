import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class ChatStarterTests: XCTestCase {
    @MainActor
    private final class OpenedChats {
        var ids: [String] = []
    }

    private func makeStarter() async throws -> (ChatStarter, OpenedChats) {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Alex")
        let client = try XCTUnwrap(model.client)
        let newChat = NewChatViewModel(client: client, debounce: .zero, sleep: { _ in })
        let opened = OpenedChats()
        return (ChatStarter(client: client, newChat: newChat) { opened.ids.append($0) }, opened)
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            await Task.yield()
        }
    }

    func testStartsChatWithFoundUser() async throws {
        let (starter, opened) = try await makeStarter()
        starter.showNewChat()
        starter.newChat.query = "sofia"
        await waitUntil {
            if case .found = starter.newChat.state { true } else { false }
        }
        guard case .found(let user) = starter.newChat.state else {
            return XCTFail("sofia not found: \(starter.newChat.state)")
        }
        XCTAssertEqual(user.userId, "user-sofia")

        await starter.startChat()

        XCTAssertEqual(opened.ids, ["chat-sofia"])
        XCTAssertNil(starter.sheet)
    }

    func testTextWithoutAccountIdSetsScanError() async throws {
        let (starter, _) = try await makeStarter()

        starter.handleScannedText("hello")

        XCTAssertNotNil(starter.scanError)
        XCTAssertNil(starter.scannedAccountId)
    }

    func testStartsChatWithAccountId() async throws {
        let (starter, opened) = try await makeStarter()
        starter.showNewChat()

        await starter.startChat(withAccountId: "user-luca")

        XCTAssertNil(starter.scanError)
        XCTAssertEqual(opened.ids.count, 1)
        XCTAssertFalse(opened.ids.first?.isEmpty ?? true)
        XCTAssertNil(starter.sheet)
    }

    func testUnknownAccountIdSetsScanError() async throws {
        let (starter, opened) = try await makeStarter()

        await starter.startChat(withAccountId: "user-nobody")

        XCTAssertNotNil(starter.scanError)
        XCTAssertTrue(opened.ids.isEmpty)
    }

    func testCreatesGroup() async throws {
        let (starter, opened) = try await makeStarter()
        starter.showNewGroup()
        starter.newGroup.name = "Trip"
        for handle in ["luca", "nikos"] {
            starter.newGroup.memberHandle = handle
            await starter.newGroup.addMember()
        }
        XCTAssertEqual(starter.newGroup.members.map(\.userId), ["user-luca", "user-nikos"])

        await starter.createGroup()

        XCTAssertEqual(opened.ids.count, 1)
        XCTAssertFalse(opened.ids.first?.isEmpty ?? true)
        XCTAssertNil(starter.sheet)
    }
}
