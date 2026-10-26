import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class OnboardingFlowTests: XCTestCase {
    func testViewModelUsesResolvedServerAndLaunchClient() async throws {
        let model = makeTestModel()
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model, recoveryKit: FakeRecoveryKitFunctions())
        XCTAssertEqual(viewModel.serverUrl, "http://localhost:8080")

        viewModel.choose(.linkDevice)
        let context = try XCTUnwrap(viewModel.context)
        let client = try await context.client()
        XCTAssertTrue(client === model.client)
    }

    func testViewModelUsesModelKeepServer() async throws {
        let defaults = makeTestDefaults()
        KeepServer.store(.custom("https://custom.keep.test"), in: defaults)
        let model = makeTestModel(defaults: defaults)
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model, recoveryKit: FakeRecoveryKitFunctions())

        viewModel.choose(.linkDevice)
        let context = try XCTUnwrap(viewModel.context)
        XCTAssertEqual(context.config.keepServerUrl, "https://custom.keep.test")
        let client = try await context.client()
        XCTAssertTrue(client === model.client)
    }

    func testLinkSignsIn() async throws {
        let defaults = makeTestDefaults()
        let model = makeTestModel(defaults: defaults)
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model, recoveryKit: FakeRecoveryKitFunctions())
        viewModel.choose(.linkDevice)
        let link = LinkThisDeviceViewModel(context: try XCTUnwrap(viewModel.context))
        await link.start()
        await link.confirm(codesMatch: true)

        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.session?.userId, FakeGimClient.demoSelfId)
        XCTAssertEqual(defaults.string(forKey: AppModel.serverUrlKey), "http://localhost:8080")
    }

    func testCreateSignsIn() async throws {
        let model = makeTestModel()
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model, recoveryKit: FakeRecoveryKitFunctions())
        viewModel.choose(.createIdentity)
        let createIdentity = try XCTUnwrap(viewModel.createIdentity)
        createIdentity.displayName = "Mac user"
        await createIdentity.submit()

        guard case .recoveryKit(let kit) = viewModel.stage else {
            return XCTFail("expected the recovery kit step, got \(String(describing: viewModel.stage))")
        }
        let code = try XCTUnwrap(kit.code)
        kit.continueToCheck()
        kit.endingInput = FakeRecoveryKitFunctions().recoveryKeyEnding(recoveryCode: code)
        kit.confirm()
        guard case .claimHandle(let claimHandle) = viewModel.stage else {
            return XCTFail("expected the username step, got \(String(describing: viewModel.stage))")
        }
        await claimHandle.skip()

        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.session?.displayName, "Mac user")
        XCTAssertEqual(model.serverUrl, "http://localhost:8080")
    }

    func testFlowsUseTheGivenRecoveryKit() async throws {
        let userId = "u" + String(String(repeating: "abcdefghijklmnopqrstuvwxyz234567", count: 2).prefix(54)) + "q"
        let stub = StubRecoveryKitFunctions(
            parsed: ParsedRecoveryKit(userId: userId, recoveryCode: String(repeating: "0", count: 39)), ending: "STUB")
        let model = makeTestModel()
        await model.start()
        let viewModel = try OnboardingFlow.makeViewModel(model: model, recoveryKit: stub)

        viewModel.choose(.restore)
        let restore = RestoreViewModel(context: try XCTUnwrap(viewModel.context))
        restore.kitText = "any text"
        XCTAssertEqual(restore.parsed, stub.parsed)
        XCTAssertEqual(restore.userId, userId)
        XCTAssertEqual(restore.recoveryCode, RecoveryKit.groupedRecoveryCode(String(repeating: "0", count: 39)))

        viewModel.choose(.createIdentity)
        let createIdentity = try XCTUnwrap(viewModel.createIdentity)
        createIdentity.displayName = "Mac user"
        await createIdentity.submit()
        guard case .recoveryKit(let kit) = viewModel.stage else {
            return XCTFail("expected the recovery kit step, got \(String(describing: viewModel.stage))")
        }
        let code = try XCTUnwrap(kit.code)
        kit.continueToCheck()
        kit.endingInput = FakeRecoveryKitFunctions().recoveryKeyEnding(recoveryCode: code)
        kit.confirm()
        XCTAssertEqual(kit.endingErrorKind, .mismatch)
        kit.endingInput = "STUB"
        kit.confirm()
        XCTAssertTrue(kit.isConfirmed)
    }
}
