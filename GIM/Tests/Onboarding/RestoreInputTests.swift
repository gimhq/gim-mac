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
    private let empty = RestoreInput.Fields(userId: "", recoveryCode: "")
    private let typed = RestoreInput.Fields(userId: "typed id", recoveryCode: "typed code")

    private var registrations: [Registration] = []

    // MARK: - Paste

    func testApplyFillsBothFromAKitInAnyLanguage() {
        for labels in [Self.english, Self.chinese] {
            let kit = RecoveryKit.format(userId: userId, recoveryCode: symbols, labels: labels)
            let (fields, outcome) = RestoreInput.apply(pasted: kit, to: typed)
            XCTAssertEqual(outcome, .filledBoth)
            XCTAssertEqual(fields, RestoreInput.Fields(userId: userId, recoveryCode: code))
        }
    }

    func testApplyFillsBothFromIdAndSymbols() {
        let (fields, outcome) = RestoreInput.apply(pasted: "\(userId.uppercased()) \(symbols.lowercased())", to: empty)
        XCTAssertEqual(outcome, .filledBoth)
        XCTAssertEqual(fields, RestoreInput.Fields(userId: userId, recoveryCode: code))
    }

    func testApplyFindsTheKitInCRLFProse() {
        let kit = RecoveryKit.format(userId: userId, recoveryCode: code, labels: Self.english)
            .replacingOccurrences(of: "\n", with: "\r\n")
        let text = "Hi,\r\n\r\nhere is my kit:\r\n\r\n\(kit)\r\nThanks!\r\n"
        let (fields, outcome) = RestoreInput.apply(pasted: text, to: empty)
        XCTAssertEqual(outcome, .filledBoth)
        XCTAssertEqual(fields, RestoreInput.Fields(userId: userId, recoveryCode: code))
    }

    func testApplyWithOneValueKeepsTheOtherField() {
        let idOnly = RestoreInput.apply(pasted: "Account ID: \(userId)", to: typed)
        XCTAssertEqual(idOnly.outcome, .filledUserIdOnly)
        XCTAssertEqual(idOnly.fields, RestoreInput.Fields(userId: userId, recoveryCode: "typed code"))

        let codeOnly = RestoreInput.apply(pasted: "my key is \(symbols)", to: typed)
        XCTAssertEqual(codeOnly.outcome, .filledCodeOnly)
        XCTAssertEqual(codeOnly.fields, RestoreInput.Fields(userId: "typed id", recoveryCode: code))
    }

    func testApplyWithGarbageChangesNothing() {
        let (fields, outcome) = RestoreInput.apply(pasted: "hello, this is not a kit at all!", to: typed)
        XCTAssertEqual(outcome, .nothingFound)
        XCTAssertEqual(fields, typed)
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
        XCTAssertTrue(RestoreInput.canSubmit(RestoreInput.Fields(userId: userId, recoveryCode: code)))
        XCTAssertTrue(RestoreInput.canSubmit(RestoreInput.Fields(userId: " \(userId) ", recoveryCode: symbols)))
        XCTAssertFalse(RestoreInput.canSubmit(empty))
        XCTAssertFalse(RestoreInput.canSubmit(RestoreInput.Fields(userId: userId, recoveryCode: "")))
        XCTAssertFalse(RestoreInput.canSubmit(RestoreInput.Fields(userId: "", recoveryCode: code)))
        XCTAssertFalse(RestoreInput.canSubmit(RestoreInput.Fields(userId: userId, recoveryCode: String(code.prefix(20)))))
        XCTAssertFalse(RestoreInput.canSubmit(RestoreInput.Fields(userId: "uabc", recoveryCode: code)))
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
        let kit = RecoveryKit.format(userId: userId, recoveryCode: code, labels: Self.english)
        let (fields, outcome) = RestoreInput.apply(
            pasted: kit, to: RestoreInput.Fields(userId: viewModel.userId, recoveryCode: viewModel.recoveryCode))
        // The fake's ids ("user-...") are not gim-core user ids, so only the code is found and the id is typed.
        XCTAssertEqual(outcome, RecoveryKit.isValidUserId(userId) ? .filledBoth : .filledCodeOnly)
        XCTAssertEqual(fields.recoveryCode, RecoveryKit.formatRecoveryCode(RecoveryKit.normalizeRecoveryCode(code)))
        viewModel.userId = RecoveryKit.isValidUserId(userId) ? fields.userId : userId
        viewModel.recoveryCode = fields.recoveryCode

        await viewModel.submit()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showsRejoinNotice)
        XCTAssertTrue(registrations.isEmpty)

        viewModel.finish()
        XCTAssertEqual(registrations.count, 1)
        XCTAssertEqual(registrations.first?.session.userId, userId)
        XCTAssertFalse(viewModel.showsRejoinNotice)
    }

    func testRestoreWithWrongCodeShowsTheError() async throws {
        let (userId, code, viewModel) = try await makeSignedOut()
        XCTAssertNotEqual(RecoveryKit.normalizeRecoveryCode(code), symbols)
        viewModel.userId = userId
        viewModel.recoveryCode = Self.code

        await viewModel.submit()
        XCTAssertEqual(viewModel.errorMessage, "This recovery code doesn't match this user ID.")
        XCTAssertFalse(viewModel.showsRejoinNotice)
        XCTAssertTrue(registrations.isEmpty)
    }
}
