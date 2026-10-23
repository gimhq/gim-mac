import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class AccountDevicesTests: XCTestCase {
    private func makeClient() -> FakeGimClient {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-devices-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return FakeGimClient.demo(
            scheduler: ImmediateFakeScheduler(), dataDirectory: directory.path, registered: true)
    }

    func testDeviceLabelNamesThisMac() {
        let device = DeviceInfo(deviceId: "device-abcdef123", createdAtMs: 1, isCurrent: true, revoked: false)
        XCTAssertEqual(SettingsText.deviceLabel(device), "This Mac")
    }

    func testDeviceLabelShortensOtherDeviceId() {
        let device = DeviceInfo(deviceId: "device-abcdef123", createdAtMs: 1, isCurrent: false, revoked: false)
        XCTAssertEqual(SettingsText.deviceLabel(device), "Device device-a")
    }

    func testDevicesListThisMacFirstAndTheOtherDevice() async {
        let devices = DevicesViewModel(client: makeClient())
        await devices.load()
        XCTAssertNil(devices.errorMessage)
        XCTAssertEqual(devices.devices.count, 2)
        XCTAssertEqual(devices.devices.first?.isCurrent, true)
        XCTAssertEqual(devices.devices.first.map(SettingsText.deviceLabel), "This Mac")
        XCTAssertTrue(devices.devices.contains { $0.deviceId == FakeGimClient.fakeOtherDeviceId && !$0.revoked })
    }

    func testRemoveDeviceMarksTheOtherDeviceRemoved() async throws {
        let devices = DevicesViewModel(client: makeClient())
        await devices.load()
        let other = try XCTUnwrap(devices.devices.first { $0.deviceId == FakeGimClient.fakeOtherDeviceId })
        XCTAssertTrue(devices.canRevoke(other))
        await devices.revoke(deviceId: other.deviceId)
        XCTAssertNil(devices.errorMessage)
        let removed = try XCTUnwrap(devices.devices.first { $0.deviceId == FakeGimClient.fakeOtherDeviceId })
        XCTAssertTrue(removed.revoked)
        XCTAssertFalse(devices.canRevoke(removed))
    }

    func testLinkCodeShowsNumbersAndMatchLinksTheDevice() async throws {
        let client = makeClient()
        let link = ApproveLinkViewModel(client: client)
        link.linkCode = "gim-link:fake:1"
        await link.submit()
        XCTAssertNil(link.errorMessage)
        XCTAssertEqual(link.sas, FakeGimClient.fakeSas)
        XCTAssertFalse(link.canApprove)
        let newDeviceId = try XCTUnwrap(link.newDeviceId)

        await link.confirm(codesMatch: true)
        XCTAssertEqual(link.outcome, .linked)
        let devices = DevicesViewModel(client: client)
        await devices.load()
        let added = try XCTUnwrap(devices.devices.first { $0.deviceId == newDeviceId })
        XCTAssertFalse(added.revoked)
    }

    func testNumbersDontMatchRejectsTheDevice() async throws {
        let client = makeClient()
        let link = ApproveLinkViewModel(client: client)
        link.linkCode = "gim-link:fake:1"
        await link.submit()
        let newDeviceId = try XCTUnwrap(link.newDeviceId)

        await link.confirm(codesMatch: false)
        XCTAssertEqual(link.outcome, .rejected)
        let devices = DevicesViewModel(client: client)
        await devices.load()
        let rejected = try XCTUnwrap(devices.devices.first { $0.deviceId == newDeviceId })
        XCTAssertTrue(rejected.revoked)
    }
}
