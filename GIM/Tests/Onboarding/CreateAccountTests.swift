import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class CreateAccountTests: XCTestCase {
    private let recoveryKit = FakeRecoveryKitFunctions()
    private var registrations: [Registration] = []

    private func makeViewModel(serverUrl: String = "http://localhost:8080") -> OnboardingViewModel {
        OnboardingViewModel(
            factory: FakeGimClientFactory(scheduler: ImmediateFakeScheduler()),
            hooks: TestPlatformHooks(),
            recoveryKit: recoveryKit,
            serverUrl: serverUrl,
            onRegistered: { [unowned self] in self.registrations.append($0) })
    }

    // MARK: - Recovery kit

    func testLastFourCheckUsesTheCodeEnding() async throws {
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: ClientConfig(serverUrl: "http://localhost:8080"), hooks: TestPlatformHooks())
        let code = try await client.createIdentity(displayName: "Mac user")
        let ending = recoveryKit.recoveryKeyEnding(recoveryCode: code)
        XCTAssertEqual(ending.count, 4)
        var confirmed = 0
        let kit = RecoveryKitViewModel(userId: "user-mac", code: code, recoveryKit: recoveryKit) { confirmed += 1 }
        kit.continueToCheck()
        XCTAssertTrue(kit.isChecking)

        for wrong in [String(ending.dropLast()) + (ending.last == "0" ? "1" : "0"), String(ending.dropFirst()), ""] {
            kit.endingInput = wrong
            kit.confirm()
            XCTAssertEqual(kit.endingErrorKind, .mismatch)
            XCTAssertFalse(kit.isConfirmed)
        }
        kit.showKitAgain()
        XCTAssertFalse(kit.isChecking)
        kit.continueToCheck()
        XCTAssertNil(kit.endingErrorKind)

        kit.endingInput = " " + ending.lowercased().map(String.init).joined(separator: " ") + " "
        kit.confirm()
        XCTAssertNil(kit.endingErrorKind)
        XCTAssertTrue(kit.isConfirmed)
        XCTAssertEqual(confirmed, 1)
    }

    func testKitTextUsesTheLocalizedLabels() async throws {
        let userId = "u" + String(String(repeating: "abcdefghijklmnopqrstuvwxyz234567", count: 2).prefix(54)) + "q"
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: ClientConfig(serverUrl: "http://localhost:8080"), hooks: TestPlatformHooks())
        let code = try await client.createIdentity(displayName: "Mac user")
        let kit = RecoveryKitViewModel(userId: userId, code: code, recoveryKit: recoveryKit) {}
        XCTAssertEqual(
            kit.kitText, recoveryKit.formatRecoveryKit(userId: userId, recoveryCode: code, labels: .localized))
        XCTAssertTrue(kit.kitText.hasPrefix("\(RecoveryKitLabels.localized.title)\n"))
        let parsed = recoveryKit.parseRecoveryKit(text: kit.kitText)
        XCTAssertEqual(parsed.userId, userId)
        let parsedCode = try XCTUnwrap(parsed.recoveryCode)
        XCTAssertTrue(
            recoveryKit.matchesRecoveryKeyEnding(
                recoveryCode: code, typed: recoveryKit.recoveryKeyEnding(recoveryCode: parsedCode)))
    }

    // MARK: - Create flow

    func testCreateFlowReachesRegistration() async throws {
        let viewModel = makeViewModel()
        viewModel.choose(.createIdentity)
        let createIdentity = try XCTUnwrap(viewModel.createIdentity)
        createIdentity.displayName = "Mac user"
        await createIdentity.submit()

        guard case .recoveryKit(let kit) = viewModel.stage else {
            return XCTFail("expected the recovery kit step, got \(String(describing: viewModel.stage))")
        }
        let code = try XCTUnwrap(kit.code)
        XCTAssertNotNil(recoveryKit.parseRecoveryKit(text: code).recoveryCode)
        XCTAssertFalse(kit.userId.isEmpty)
        kit.continueToCheck()
        XCTAssertTrue(kit.isChecking)
        kit.endingInput = recoveryKit.recoveryKeyEnding(recoveryCode: code)
        kit.confirm()

        XCTAssertEqual(registrations.count, 1)
        XCTAssertEqual(registrations.first?.session.displayName, "Mac user")
    }

    // MARK: - Server rule

    func testChooseCreateWithValidServerOpensTheNameStep() {
        let viewModel = makeViewModel()
        viewModel.choose(.createIdentity)
        XCTAssertEqual(viewModel.path, [.createIdentity])
        XCTAssertNotNil(viewModel.createIdentity)
        XCTAssertNil(viewModel.serverUrlError)
    }

    func testChooseCreateWithInvalidServerStays() {
        let viewModel = makeViewModel(serverUrl: "not a url")
        viewModel.choose(.createIdentity)
        XCTAssertTrue(viewModel.path.isEmpty)
        XCTAssertNotNil(viewModel.serverUrlError)
    }
}
