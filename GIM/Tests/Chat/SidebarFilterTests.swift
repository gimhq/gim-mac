import GIMClientKit
import XCTest

@testable import GIM

@MainActor
final class SidebarFilterTests: XCTestCase {
    func testSearchTextFiltersRowsAndClearingRestoresThem() async throws {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Alex")
        let sidebar = try XCTUnwrap(model.sidebar)
        let deadline = ContinuousClock.now + .seconds(2)
        while sidebar.rows.count < 2, ContinuousClock.now < deadline {
            await Task.yield()
            try await Task.sleep(for: .milliseconds(20))
        }
        let allIds = Set(sidebar.rows.map(\.id))
        XCTAssertEqual(allIds, [FakeGimClient.demoDirectChatId, FakeGimClient.demoGroupChatId])

        sidebar.searchText = "aegean"
        XCTAssertEqual(sidebar.rows.map(\.id), ["chat-crew"])
        sidebar.select(index: 0)
        XCTAssertEqual(sidebar.selectedChatId, "chat-crew")

        sidebar.searchText = ""
        XCTAssertEqual(Set(sidebar.rows.map(\.id)), allIds)
    }
}
