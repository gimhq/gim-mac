import GIMClientKit
import XCTest

@testable import GIM

@MainActor
final class ProfileModelTests: XCTestCase {
    private func makeClient() -> FakeGimClient {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-profile-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return FakeGimClient.demo(
            scheduler: ImmediateFakeScheduler(), dataDirectory: directory.path, registered: true)
    }

    func testLoadFillsSessionAndDrafts() async {
        let profile = ProfileModel(client: makeClient())
        await profile.load()
        XCTAssertEqual(profile.session?.displayName, "Alex Morgan")
        XCTAssertEqual(profile.displayNameDraft, "Alex Morgan")
        XCTAssertEqual(profile.handleDraft, "alex")
        XCTAssertEqual(profile.accountId, FakeGimClient.demoSelfId)
        XCTAssertTrue(profile.hasHandle)
        XCTAssertNil(profile.errorMessage)
    }

    func testSaveDisplayNameChangesSession() async throws {
        let client = makeClient()
        let profile = ProfileModel(client: client)
        await profile.load()
        profile.displayNameDraft = "  Alex M.  "
        await profile.saveDisplayName()
        XCTAssertNil(profile.errorMessage)
        XCTAssertEqual(profile.session?.displayName, "Alex M.")
        let stored = try await client.session()
        XCTAssertEqual(stored?.displayName, "Alex M.")
    }

    func testEmptyNameSetsErrorWithoutCallingClient() async throws {
        let client = makeClient()
        let profile = ProfileModel(client: client)
        await profile.load()
        profile.displayNameDraft = "   "
        await profile.saveDisplayName()
        XCTAssertEqual(profile.errorMessage, String(localized: "settings.profile.nameEmpty", table: "Settings"))
        let stored = try await client.session()
        XCTAssertEqual(stored?.displayName, "Alex Morgan")
    }

    func testClaimHandleSetsHandle() async {
        let profile = ProfileModel(client: makeClient())
        await profile.load()
        profile.handleDraft = " Alex_M "
        await profile.claimHandle()
        XCTAssertNil(profile.errorMessage)
        XCTAssertEqual(profile.session?.handle, "alex_m")
    }

    func testClaimTakenHandleShowsTakenMessage() async {
        let profile = ProfileModel(client: makeClient())
        await profile.load()
        profile.handleDraft = "sofia"
        await profile.claimHandle()
        XCTAssertEqual(
            profile.errorMessage, String(localized: "settings.profile.usernameTaken", table: "Settings"))
        XCTAssertEqual(profile.session?.handle, "alex")
    }

    func testRemoveHandleClearsIt() async {
        let profile = ProfileModel(client: makeClient())
        await profile.load()
        await profile.removeHandle()
        XCTAssertNil(profile.errorMessage)
        XCTAssertEqual(profile.session?.handle, "")
        XCTAssertFalse(profile.hasHandle)
    }
}
