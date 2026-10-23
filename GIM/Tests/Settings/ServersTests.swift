import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class ServersTests: XCTestCase {
    private func makeClient() -> FakeGimClient {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-servers-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return FakeGimClient.demo(
            scheduler: ImmediateFakeScheduler(), dataDirectory: directory.path, registered: true)
    }

    func testHubStateKeys() {
        XCTAssertEqual(SettingsText.hubStateKey(.verified), "settings.servers.connected")
        XCTAssertEqual(SettingsText.hubStateKey(.unverified), "settings.servers.notChecked")
        XCTAssertEqual(SettingsText.hubStateKey(.removed), "settings.servers.removed")
    }

    func testNoticeKeys() {
        XCTAssertEqual(SettingsText.noticeKey(title: "Can't Remove Home Hub"), "settings.servers.cantRemoveMain")
        XCTAssertEqual(SettingsText.noticeKey(title: "Can't Remove Last Hub"), "settings.servers.cantRemoveLast")
        XCTAssertEqual(SettingsText.noticeKey(title: "Try Again Later"), "settings.servers.tryLater")
        XCTAssertEqual(SettingsText.noticeKey(title: "Something New"), "settings.servers.cantRemove")
        XCTAssertEqual(
            SettingsText.noticeMessageKey(title: "Can't Remove Home Hub"), "settings.servers.cantRemoveMainBody")
        XCTAssertNil(SettingsText.noticeMessageKey(title: "Something New"))
    }

    func testAddServerErrorKeys() {
        XCTAssertEqual(SettingsText.addServerErrorKey(ErrorPresenter.hubRefusedMessage), "settings.addServer.refused")
        XCTAssertEqual(
            SettingsText.addServerErrorKey(ErrorPresenter.message(for: GimError.HubNotVerified(reason: "x"))),
            "settings.addServer.notVerified")
        XCTAssertNil(SettingsText.addServerErrorKey("Something went wrong."))
    }

    func testHomeServerIsMainAndConnected() async throws {
        let hubs = HubsViewModel(client: makeClient())
        hubs.start()
        defer { hubs.stop() }
        try await waitUntil { !hubs.isLoading }
        let home = try XCTUnwrap(hubs.hubs.first)
        XCTAssertTrue(home.isPrimary)
        XCTAssertEqual(SettingsText.hubStateKey(home.state), "settings.servers.connected")
        XCTAssertFalse(hubs.canSetPrimary(home))
    }

    func testRemovingTheMainServerExplainsWhy() async throws {
        let hubs = HubsViewModel(client: makeClient())
        hubs.start()
        defer { hubs.stop() }
        try await waitUntil { !hubs.isLoading }
        let home = try XCTUnwrap(hubs.hubs.first)
        hubs.requestRemoval(home)
        XCTAssertEqual(hubs.pendingRemoval, home)
        await hubs.confirmRemoval(of: home)
        let notice = try XCTUnwrap(hubs.notice)
        XCTAssertEqual(SettingsText.noticeKey(title: notice.title), "settings.servers.cantRemoveMain")
    }

    func testAddThenRemoveServer() async throws {
        let client = makeClient()
        let hubs = HubsViewModel(client: client)
        hubs.start()
        defer { hubs.stop() }
        try await waitUntil { !hubs.isLoading }

        let addHub = AddHubViewModel(client: client)
        addHub.url = "https://second.example.eu"
        XCTAssertTrue(addHub.canSubmit)
        await addHub.submit()
        XCTAssertNil(addHub.errorMessage)
        let added = try XCTUnwrap(addHub.addedHub)
        try await waitUntil { hubs.hubs.contains { $0.hubId == added.hubId && $0.state == .verified } }

        let listed = try XCTUnwrap(hubs.hubs.first { $0.hubId == added.hubId })
        XCTAssertTrue(hubs.canRemove(listed))
        await hubs.confirmRemoval(of: listed)
        XCTAssertNil(hubs.errorMessage)
        try await waitUntil { hubs.hubs.contains { $0.hubId == added.hubId && $0.state == .removed } }
    }

    func testServerWithOwnGroupsAsksAgainBeforeRemoving() async throws {
        let client = makeClient()
        let hubs = HubsViewModel(client: client)
        hubs.start()
        defer { hubs.stop() }
        try await waitUntil { !hubs.isLoading }

        let addHub = AddHubViewModel(client: client)
        addHub.url = "https://owner.example.eu"
        await addHub.submit()
        let added = try XCTUnwrap(addHub.addedHub)
        try await waitUntil { hubs.hubs.contains { $0.hubId == added.hubId && $0.state == .verified } }

        let listed = try XCTUnwrap(hubs.hubs.first { $0.hubId == added.hubId })
        await hubs.confirmRemoval(of: listed)
        let warning = try XCTUnwrap(hubs.ownedGroupsWarning)
        XCTAssertEqual(warning.groupCount, 2)
        await hubs.confirmOwnedGroupsRemoval(warning)
        try await waitUntil { hubs.hubs.contains { $0.hubId == added.hubId && $0.state == .removed } }
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(2)
        while !condition(), ContinuousClock.now < deadline {
            await Task.yield()
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertTrue(condition())
    }
}
