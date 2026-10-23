import Foundation
import GIMClientKit
import XCTest

@testable import GIM

@MainActor
final class SelectionAndRoutingTests: XCTestCase {
    func testSidebarListsDemoChatsAndMovesSelection() async throws {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Demo user")
        let sidebar = try XCTUnwrap(model.sidebar)

        let deadline = ContinuousClock.now + .seconds(2)
        while sidebar.rows.count < 2, ContinuousClock.now < deadline {
            await Task.yield()
            try await Task.sleep(for: .milliseconds(20))
        }
        let ids = sidebar.rows.map(\.id)
        XCTAssertTrue(ids.contains(FakeGimClient.demoDirectChatId), "rows: \(ids)")
        XCTAssertTrue(ids.contains(FakeGimClient.demoGroupChatId), "rows: \(ids)")
        XCTAssertFalse(sidebar.isLoading)
        XCTAssertNil(sidebar.errorMessage)
        XCTAssertNil(sidebar.selectedChatId)

        let rows = sidebar.rows
        sidebar.select(index: 0)
        XCTAssertEqual(sidebar.selectedChatId, rows[0].id)
        XCTAssertEqual(model.selectedChatId, rows[0].id)
        XCTAssertEqual(sidebar.title(for: rows[0].id), rows[0].title)

        sidebar.selectNext()
        XCTAssertEqual(sidebar.selectedChatId, rows[1].id)

        sidebar.select(index: 42)
        XCTAssertEqual(sidebar.selectedChatId, rows[1].id)

        sidebar.selectPrevious()
        XCTAssertEqual(sidebar.selectedChatId, rows[0].id)
        sidebar.selectPrevious()
        XCTAssertEqual(sidebar.selectedChatId, rows[0].id)

        XCTAssertNil(sidebar.title(for: "no-such-chat"))
    }

    func testSelectNextWithoutSelectionPicksFirstRow() async throws {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Demo user")
        let sidebar = try XCTUnwrap(model.sidebar)
        let deadline = ContinuousClock.now + .seconds(2)
        while sidebar.rows.isEmpty, ContinuousClock.now < deadline {
            await Task.yield()
            try await Task.sleep(for: .milliseconds(20))
        }
        sidebar.selectNext()
        XCTAssertEqual(sidebar.selectedChatId, sidebar.rows.first?.id)
    }

    func testSignOutDropsSidebar() async throws {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Demo user")
        XCTAssertNotNil(model.sidebar)
        _ = await model.signOut()
        XCTAssertNil(model.sidebar)
        XCTAssertNil(model.selectedChatId)
    }

    func testChatWindowIDRoundTripsThroughJSON() throws {
        let id = ChatWindowID(chatId: FakeGimClient.demoDirectChatId)
        let data = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(ChatWindowID.self, from: data)
        XCTAssertEqual(decoded, id)
        XCTAssertEqual(decoded.chatId, "chat-sofia")
        XCTAssertEqual(ChatWindowID.windowGroupID, "chat")
    }
}
