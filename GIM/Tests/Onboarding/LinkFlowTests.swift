import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class LinkFlowTests: XCTestCase {
    private var discarded = 0
    private var registrations: [Registration] = []

    /// A fake client without a session and a link view model whose context counts discards and registrations.
    private func makeViewModel() async throws -> (any GimClientAPI, LinkThisDeviceViewModel) {
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: ClientConfig(serverUrl: "http://localhost:8080"), hooks: TestPlatformHooks())
        let context = OnboardingContext(
            config: ClientConfig(serverUrl: "http://localhost:8080"),
            client: { client },
            discardClient: { [unowned self] in self.discarded += 1 },
            onRegistered: { [unowned self] in self.registrations.append($0) })
        return (client, LinkThisDeviceViewModel(context: context))
    }

    func testStartEndsComparingWithSession() async throws {
        let (client, viewModel) = try await makeViewModel()
        await viewModel.start()
        XCTAssertEqual(viewModel.step, .comparing(sas: FakeGimClient.fakeSas))
        let session = try await client.session()
        XCTAssertNotNil(session)
    }

    func testMatchingCodesLinkAndRegister() async throws {
        let (_, viewModel) = try await makeViewModel()
        await viewModel.start()
        await viewModel.confirm(codesMatch: true)
        XCTAssertEqual(viewModel.step, .linked)
        XCTAssertEqual(registrations.count, 1)
        let registration = try XCTUnwrap(registrations.first)
        XCTAssertEqual(registration.session.userId, FakeDemoData.demoSelfId)
        XCTAssertEqual(registration.config.serverUrl, "http://localhost:8080")
    }

    func testMismatchedCodesRejectAndWipe() async throws {
        let (client, viewModel) = try await makeViewModel()
        await viewModel.start()
        await viewModel.confirm(codesMatch: false)
        XCTAssertEqual(viewModel.step, .rejected)
        XCTAssertEqual(discarded, 1)
        let session = try await client.session()
        XCTAssertNil(session)
        XCTAssertTrue(registrations.isEmpty)
    }

    func testConfirmBeforeComparingDoesNothing() async throws {
        let (_, viewModel) = try await makeViewModel()
        await viewModel.confirm(codesMatch: true)
        XCTAssertEqual(viewModel.step, .starting)
        XCTAssertTrue(registrations.isEmpty)
    }

    func testQRCodeImageRendersLinkCode() throws {
        let image = try XCTUnwrap(QRCodeImage.makeImage("gim-link:fake:1"))
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }
}
