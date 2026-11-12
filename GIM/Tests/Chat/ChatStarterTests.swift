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

    /// - Parameter remoteUsers: added to the demo client, whose own users have no valid Account IDs.
    private func makeStarter(remoteUsers: [UserProfile] = []) async throws -> (ChatStarter, OpenedChats) {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Alex")
        let client = try XCTUnwrap(model.client)
        let fake = try XCTUnwrap(client as? FakeGimClient)
        for user in remoteUsers { await fake.addRemoteUser(user) }
        let opened = OpenedChats()
        return (ChatStarter(client: client) { opened.ids.append($0) }, opened)
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
        let ids = ["l", "n"].map { "u" + String(repeating: $0, count: 54) + "a" }
        let (starter, opened) = try await makeStarter(
            remoteUsers: ids.map { UserProfile(userId: $0, handle: "", displayName: $0) })
        starter.showNewGroup()
        starter.newGroup.name = "Trip"
        starter.newGroup.memberAccountId = "Account ID: \(ids[0].uppercased())"
        await starter.newGroup.addMember()
        starter.newGroup.memberAccountId = ids[1]
        await starter.newGroup.addMember()
        XCTAssertNil(starter.newGroup.memberError)
        XCTAssertEqual(starter.newGroup.members.map(\.userId), ids)

        await starter.createGroup()

        XCTAssertEqual(opened.ids.count, 1)
        XCTAssertFalse(opened.ids.first?.isEmpty ?? true)
        XCTAssertNil(starter.sheet)
    }

    func testRejectsMemberTextWithoutAccountId() async throws {
        let (starter, _) = try await makeStarter()
        starter.newGroup.memberAccountId = "sofia"
        await starter.newGroup.addMember()
        XCTAssertNotNil(starter.newGroup.memberError)
        XCTAssertTrue(starter.newGroup.members.isEmpty)
    }
}
