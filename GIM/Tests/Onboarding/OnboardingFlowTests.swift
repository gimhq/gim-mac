import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class OnboardingFlowTests: XCTestCase {
    func testViewModelUsesResolvedServerAndLaunchClient() async throws {
        let model = makeTestModel()
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model)
        XCTAssertEqual(viewModel.serverUrl, "http://localhost:8080")

        viewModel.choose(.linkDevice)
        let context = try XCTUnwrap(viewModel.context)
        let client = try await context.client()
        XCTAssertTrue(client === model.client)
    }

    func testLinkSignsIn() async throws {
        let defaults = makeTestDefaults()
        let model = makeTestModel(defaults: defaults)
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model)
        viewModel.choose(.linkDevice)
        let link = LinkThisDeviceViewModel(context: try XCTUnwrap(viewModel.context))
        await link.start()
        await link.confirm(codesMatch: true)

        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.session?.userId, FakeDemoData.demoSelfId)
        XCTAssertEqual(defaults.string(forKey: AppModel.serverUrlKey), "http://localhost:8080")
    }

    func testCreateSignsIn() async throws {
        let model = makeTestModel()
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model)
        viewModel.choose(.createIdentity)
        let createIdentity = try XCTUnwrap(viewModel.createIdentity)
        createIdentity.displayName = "Mac user"
        await createIdentity.submit()

        guard case .recoveryCode(let recoveryCode) = viewModel.stage else {
            return XCTFail("expected the recovery code step, got \(String(describing: viewModel.stage))")
        }
        let groups = recoveryCode.groups
        recoveryCode.continueToConfirmation()
        recoveryCode.confirmationInput = groups[recoveryCode.confirmationGroupIndex]
        recoveryCode.confirm()
        guard case .claimHandle(let claimHandle) = viewModel.stage else {
            return XCTFail("expected the username step, got \(String(describing: viewModel.stage))")
        }
        await claimHandle.skip()

        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.session?.displayName, "Mac user")
        XCTAssertEqual(model.serverUrl, "http://localhost:8080")
    }
}
