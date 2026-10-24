import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

@MainActor
final class RestoreInputTests: XCTestCase {
    private static let userId =
        "u" + String(String(repeating: "abcdefghijklmnopqrstuvwxyz234567", count: 2).prefix(54)) + "q"
    private static let code = "7BQ2-K9MX-4TVA-0HZR-PC63-W8NE-1SJD-5GFY-QK2M-V7R"
    private static let symbols = code.replacingOccurrences(of: "-", with: "")
    private static let english = RecoveryKitLabels(
        title: "Recovery kit", accountId: "Account ID", recoveryKey: "Recovery key", note: "Keep this safe.")
    private static let chinese = RecoveryKitLabels(
        title: "恢复工具包", accountId: "账户 ID", recoveryKey: "恢复密钥", note: "请妥善保管。")

    private var userId: String { Self.userId }
    private var code: String { Self.code }
    private var symbols: String { Self.symbols }

    private var registrations: [Registration] = []

    // MARK: - Paste

    /// A restore view model whose client is never used; `userId` and `recoveryCode` start typed.
    private func makeTypedViewModel() -> RestoreViewModel {
        let viewModel = RestoreViewModel(
            context: OnboardingContext(
                config: ClientConfig(serverUrl: "http://localhost:8080"),
                client: { throw GimError.Cancelled },
                discardClient: {},
                onRegistered: { _ in }))
        viewModel.userId = "typed id"
        viewModel.recoveryCode = "typed code"
        return viewModel
    }

    func testKitInAnyLanguageFillsBoth() {
        for labels in [Self.english, Self.chinese] {
            let viewModel = makeTypedViewModel()
            viewModel.kitText = GIM.RecoveryKit.format(userId: userId, recoveryCode: symbols, labels: labels)
            XCTAssertEqual(viewModel.userId, userId)
            XCTAssertEqual(viewModel.recoveryCode, code)
            XCTAssertNil(viewModel.kitErrorKind)
            XCTAssertTrue(viewModel.showsFields)
        }
    }

    func testIdAndSymbolsFillBoth() {
        let viewModel = makeTypedViewModel()
        viewModel.kitText = "\(userId.uppercased()) \(symbols.lowercased())"
        XCTAssertEqual(viewModel.userId, userId)
        XCTAssertEqual(viewModel.recoveryCode, code)
        XCTAssertNil(viewModel.kitErrorKind)
    }

    func testKitInCRLFProseFillsBoth() {
        let kit = GIM.RecoveryKit.format(userId: userId, recoveryCode: code, labels: Self.english)
            .replacingOccurrences(of: "\n", with: "\r\n")
        let viewModel = makeTypedViewModel()
        viewModel.kitText = "Hi,\r\n\r\nhere is my kit:\r\n\r\n\(kit)\r\nThanks!\r\n"
        XCTAssertEqual(viewModel.userId, userId)
        XCTAssertEqual(viewModel.recoveryCode, code)
        XCTAssertNil(viewModel.kitErrorKind)
    }

    func testKitWithOnePartKeepsTheOtherField() {
        let idOnly = makeTypedViewModel()
        idOnly.kitText = "Account ID: \(userId)"
        XCTAssertEqual(idOnly.kitErrorKind, .kitPartMissing)
        XCTAssertEqual(idOnly.userId, userId)
        XCTAssertEqual(idOnly.recoveryCode, "typed code")
        XCTAssertTrue(idOnly.showsFields)

        let codeOnly = makeTypedViewModel()
        codeOnly.kitText = "my key is \(symbols)"
        XCTAssertEqual(codeOnly.kitErrorKind, .kitPartMissing)
        XCTAssertEqual(codeOnly.userId, "typed id")
        XCTAssertEqual(codeOnly.recoveryCode, code)
    }

    func testGarbageChangesNothingAndHidesTheFields() {
        let viewModel = makeTypedViewModel()
        viewModel.kitText = "hello, this is not a kit at all!"
        XCTAssertEqual(viewModel.kitErrorKind, .kitNotRecognized)
        XCTAssertEqual(viewModel.userId, "typed id")
        XCTAssertEqual(viewModel.recoveryCode, "typed code")
        XCTAssertFalse(viewModel.showsFields)

        viewModel.enterSeparately()
        XCTAssertTrue(viewModel.showsFields)
        viewModel.kitText = " \n"
        XCTAssertNil(viewModel.kitErrorKind)
    }

    // MARK: - Field checks

    func testUserIdMessageKey() {
        XCTAssertNil(RestoreInput.userIdMessageKey(""))
        XCTAssertNil(RestoreInput.userIdMessageKey(userId))
        XCTAssertNil(RestoreInput.userIdMessageKey(" \(userId.uppercased())\n"))
        XCTAssertEqual(RestoreInput.userIdMessageKey("uabc"), "onboarding.restore.errorUserId")
        XCTAssertEqual(RestoreInput.userIdMessageKey("x" + String(userId.dropFirst())), "onboarding.restore.errorUserId")
    }

    func testRecoveryCodeMessageKey() {
        XCTAssertNil(RestoreInput.recoveryCodeMessageKey(""))
        XCTAssertNil(RestoreInput.recoveryCodeMessageKey(code))
        XCTAssertNil(RestoreInput.recoveryCodeMessageKey(code.lowercased().replacingOccurrences(of: "-", with: " ")))
        XCTAssertNil(RestoreInput.recoveryCodeMessageKey(String(code.prefix(12))))
        XCTAssertEqual(RestoreInput.recoveryCodeMessageKey("7BQ2-U9MX"), "onboarding.restore.errorCode")
        XCTAssertEqual(RestoreInput.recoveryCodeMessageKey(code + "0"), "onboarding.restore.errorCode")
        XCTAssertEqual(RestoreInput.recoveryCodeMessageKey(String(code.dropLast()) + "S"), "onboarding.restore.errorCode")
    }

    func testCanSubmitOnlyForAValidPair() {
        XCTAssertTrue(RestoreInput.canSubmit(userId: userId, recoveryCode: code))
        XCTAssertTrue(RestoreInput.canSubmit(userId: " \(userId) ", recoveryCode: symbols))
        XCTAssertFalse(RestoreInput.canSubmit(userId: "", recoveryCode: ""))
        XCTAssertFalse(RestoreInput.canSubmit(userId: userId, recoveryCode: ""))
        XCTAssertFalse(RestoreInput.canSubmit(userId: "", recoveryCode: code))
        XCTAssertFalse(RestoreInput.canSubmit(userId: userId, recoveryCode: String(code.prefix(20))))
        XCTAssertFalse(RestoreInput.canSubmit(userId: "uabc", recoveryCode: code))
    }

    // MARK: - Fake client

    /// A fake client that created an identity and signed out again, with a restore view model on it.
    private func makeSignedOut() async throws -> (userId: String, code: String, viewModel: RestoreViewModel) {
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: ClientConfig(serverUrl: "http://localhost:8080"), hooks: TestPlatformHooks())
        let code = try await client.createIdentity(displayName: "Restore test")
        let userId = try XCTUnwrap(client.userId())
        try await client.signOut()
        let context = OnboardingContext(
            config: ClientConfig(serverUrl: "http://localhost:8080"),
            client: { client },
            discardClient: {},
            onRegistered: { [unowned self] in self.registrations.append($0) })
        return (userId, code, RestoreViewModel(context: context))
    }

    func testRestoreFromPastedKitRegistersTheSameUser() async throws {
        let (userId, code, viewModel) = try await makeSignedOut()
        viewModel.kitText = GIM.RecoveryKit.format(userId: userId, recoveryCode: code, labels: Self.english)
        // The fake's ids ("user-...") are not gim-core user ids, so only the code is found and the id is typed.
        if GIM.RecoveryKit.isValidUserId(userId) {
            XCTAssertNil(viewModel.kitErrorKind)
        } else {
            XCTAssertEqual(viewModel.kitErrorKind, .kitPartMissing)
            viewModel.userId = userId
        }
        XCTAssertEqual(
            viewModel.recoveryCode,
            GIM.RecoveryKit.formatRecoveryCode(GIM.RecoveryKit.normalizeRecoveryCode(code)))

        await viewModel.submit()
        XCTAssertNil(viewModel.errorKind)
        XCTAssertTrue(viewModel.showsRejoinNotice)
        XCTAssertTrue(registrations.isEmpty)

        viewModel.finish()
        XCTAssertEqual(registrations.count, 1)
        XCTAssertEqual(registrations.first?.session.userId, userId)
        XCTAssertFalse(viewModel.showsRejoinNotice)
    }

    func testRestoreWithWrongCodeShowsTheError() async throws {
        let (userId, code, viewModel) = try await makeSignedOut()
        XCTAssertNotEqual(GIM.RecoveryKit.normalizeRecoveryCode(code), symbols)
        viewModel.userId = userId
        viewModel.recoveryCode = Self.code

        await viewModel.submit()
        XCTAssertEqual(viewModel.errorKind, .wrongCode)
        XCTAssertFalse(viewModel.showsRejoinNotice)
        XCTAssertTrue(registrations.isEmpty)
    }
}
