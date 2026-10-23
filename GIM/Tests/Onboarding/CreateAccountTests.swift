import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class CreateAccountTests: XCTestCase {
    private var registrations: [Registration] = []

    private func makeViewModel(serverUrl: String = "http://localhost:8080") -> OnboardingViewModel {
        OnboardingViewModel(
            factory: FakeGimClientFactory(scheduler: ImmediateFakeScheduler()),
            hooks: TestPlatformHooks(),
            serverUrl: serverUrl,
            chooseGroup: { _ in 0 },
            onRegistered: { [unowned self] in self.registrations.append($0) })
    }

    // MARK: - Recovery kit

    func testLastFourCheckUsesTheCodeEnding() async throws {
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: ClientConfig(serverUrl: "http://localhost:8080"), hooks: TestPlatformHooks())
        let code = try await client.createIdentity(displayName: "Mac user")
        let ending = RecoveryKit.recoveryKeyEnding(code)
        XCTAssertEqual(ending.count, 4)

        XCTAssertTrue(RecoveryKitView.endingMatches(code: code, typed: ending))
        XCTAssertTrue(RecoveryKitView.endingMatches(code: code, typed: ending.lowercased()))
        let spaced = ending.map(String.init).joined(separator: " ")
        XCTAssertTrue(RecoveryKitView.endingMatches(code: code, typed: " \(spaced) "))

        let wrong = String(ending.dropLast()) + (ending.last == "0" ? "1" : "0")
        XCTAssertFalse(RecoveryKitView.endingMatches(code: code, typed: wrong))
        XCTAssertFalse(RecoveryKitView.endingMatches(code: code, typed: String(ending.dropFirst())))
        XCTAssertFalse(RecoveryKitView.endingMatches(code: code, typed: ""))
    }

    func testKitTextUsesTheCatalogLabels() async throws {
        let labels = RecoveryKitView.labels()
        XCTAssertEqual(labels.title, "gim recovery kit")
        XCTAssertEqual(labels.accountId, "Account ID")
        XCTAssertEqual(labels.recoveryKey, "Recovery key")
        XCTAssertFalse(labels.note.isEmpty)
        XCTAssertNotEqual(labels.note, "onboarding.kit.fileNote")

        let userId = "u" + String(String(repeating: "abcdefghijklmnopqrstuvwxyz234567", count: 2).prefix(54)) + "q"
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: ClientConfig(serverUrl: "http://localhost:8080"), hooks: TestPlatformHooks())
        let code = try await client.createIdentity(displayName: "Mac user")
        let text = RecoveryKit.format(userId: userId, recoveryCode: code, labels: labels)
        XCTAssertTrue(text.hasPrefix("gim recovery kit\nAccount ID: \(userId)\nRecovery key: "))
        XCTAssertEqual(
            RecoveryKit.parse(text),
            ParsedRecoveryKit(userId: userId, recoveryCode: RecoveryKit.normalizeRecoveryCode(code)))
    }

    // MARK: - Create flow

    func testCreateFlowReachesRegistration() async throws {
        let viewModel = makeViewModel()
        viewModel.choose(.createIdentity)
        let createIdentity = try XCTUnwrap(viewModel.createIdentity)
        createIdentity.displayName = "Mac user"
        await createIdentity.submit()

        guard case .recoveryCode(let recoveryCode) = viewModel.stage else {
            return XCTFail("expected the recovery code step, got \(String(describing: viewModel.stage))")
        }
        let code = try XCTUnwrap(recoveryCode.code)
        XCTAssertEqual(RecoveryKit.normalizeRecoveryCode(code).count, RecoveryKit.recoveryCodeSymbols)
        recoveryCode.continueToConfirmation()
        XCTAssertTrue(recoveryCode.isConfirming)
        recoveryCode.confirmationInput = recoveryCode.groups[0]
        recoveryCode.confirm()

        guard case .claimHandle(let claimHandle) = viewModel.stage else {
            return XCTFail("expected the username step, got \(String(describing: viewModel.stage))")
        }
        await claimHandle.skip()
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
