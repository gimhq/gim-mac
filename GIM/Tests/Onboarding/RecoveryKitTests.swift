import GIMClientKit
import XCTest

@testable import GIM

final class RecoveryKitTests: XCTestCase {
    private static let userId = "u" + String(String(repeating: "abcdefghijklmnopqrstuvwxyz234567", count: 2).prefix(54)) + "q"
    private static let code = "7BQ2-K9MX-4TVA-0HZR-PC63-W8NE-1SJD-5GFY-QK2M-V7R"
    private static let symbols = code.replacingOccurrences(of: "-", with: "")
    private static let full = ParsedRecoveryKit(userId: userId, recoveryCode: symbols)
    private static let labels = RecoveryKitLabels(
        title: "Recovery kit", accountId: "Account ID", recoveryKey: "Recovery key", note: "Keep this safe.")

    private var userId: String { Self.userId }
    private var code: String { Self.code }
    private var symbols: String { Self.symbols }
    private var full: ParsedRecoveryKit { Self.full }
    private var labels: RecoveryKitLabels { Self.labels }

    // MARK: - Kit text

    func testFormatWritesTheKitLines() {
        let text = RecoveryKit.format(
            userId: " \(userId.uppercased()) ", recoveryCode: symbols.lowercased(), labels: labels)
        XCTAssertEqual(text, "Recovery kit\nAccount ID: \(userId)\nRecovery key: \(code)\n\nKeep this safe.\n")
    }

    func testFormatThenParseRoundTrips() {
        for input in [code, symbols] {
            XCTAssertEqual(
                RecoveryKit.parse(RecoveryKit.format(userId: userId, recoveryCode: input, labels: labels)), full)
        }
    }

    func testParseIgnoresTheLabels() {
        let spanish = RecoveryKitLabels(
            title: "Kit de recuperación", accountId: "ID de cuenta", recoveryKey: "Clave de recuperación",
            note: "Guárdalo.")
        let chinese = RecoveryKitLabels(title: "恢复工具包", accountId: "账户 ID", recoveryKey: "恢复密钥", note: "请妥善保管。")
        for kitLabels in [spanish, chinese] {
            XCTAssertEqual(
                RecoveryKit.parse(RecoveryKit.format(userId: userId, recoveryCode: code, labels: kitLabels)), full)
        }
        let fullWidth = "账户 ID：\(userId)\n恢复密钥：\(code)\n"
        XCTAssertEqual(RecoveryKit.parse(fullWidth), full)
    }

    func testParseAcceptsLowercaseAndSpacedKeys() {
        XCTAssertEqual(RecoveryKit.parse("Account ID: \(userId)\nRecovery key: \(code.lowercased())\n"), full)
        XCTAssertEqual(
            RecoveryKit.parse("Account ID: \(userId)\nRecovery key: \(code.replacingOccurrences(of: "-", with: " "))\n"),
            full)
        XCTAssertEqual(RecoveryKit.parse("\(userId) \(symbols)"), full)
    }

    func testParseFindsTheKitInSurroundingText() {
        let kit = RecoveryKit.format(userId: userId, recoveryCode: code, labels: labels)
            .replacingOccurrences(of: "\n", with: "\r\n")
        let text =
            "Hi,\r\n\r\nhere is my kit:\r\n\r\n\(kit)"
            + "\r\nmy key is \(code.replacingOccurrences(of: "-", with: " ")) again.\r\n"
        XCTAssertEqual(RecoveryKit.parse(text), full)
        XCTAssertEqual(RecoveryKit.parse("Account ID: \(userId.uppercased())\r\nRecovery key: \(code)\r\n"), full)
    }

    func testParseReturnsWhateverPartIsThere() {
        XCTAssertEqual(
            RecoveryKit.parse("my key is \(code)"), ParsedRecoveryKit(userId: nil, recoveryCode: symbols))
        XCTAssertEqual(
            RecoveryKit.parse("Account ID: \(userId)"), ParsedRecoveryKit(userId: userId, recoveryCode: nil))
        XCTAssertEqual(RecoveryKit.parse(""), ParsedRecoveryKit(userId: nil, recoveryCode: nil))
        XCTAssertEqual(RecoveryKit.parse("  \n\t "), ParsedRecoveryKit(userId: nil, recoveryCode: nil))
        XCTAssertEqual(
            RecoveryKit.parse("hello, this is not a kit at all!"), ParsedRecoveryKit(userId: nil, recoveryCode: nil))
    }

    func testParseRejectsBadTokens() {
        let badPadding = String(code.dropLast()) + "S"
        XCTAssertEqual(
            RecoveryKit.parse("\(userId)\n\(badPadding)"), ParsedRecoveryKit(userId: userId, recoveryCode: nil))
        // A user ID glued to other letters is not a whole token.
        XCTAssertEqual(RecoveryKit.parse("x\(userId)"), ParsedRecoveryKit(userId: nil, recoveryCode: nil))
    }

    func testParseNeverTakesTheUserIdAsTheKey() {
        // A valid user ID followed by more symbols must not be read as (part of) a key.
        XCTAssertEqual(RecoveryKit.parse("\(userId)-0000"), ParsedRecoveryKit(userId: userId, recoveryCode: nil))
        XCTAssertEqual(RecoveryKit.parse("\(userId)-\(code)"), ParsedRecoveryKit(userId: userId, recoveryCode: symbols))
    }

    // MARK: - Key ending

    func testKeyEndingIsTheLastFourSymbols() {
        XCTAssertEqual(RecoveryKit.recoveryKeyEnding(code), "MV7R")
        XCTAssertEqual(RecoveryKit.recoveryKeyEnding(symbols.lowercased()), "MV7R")
    }

    func testKeyEndingMatchIgnoresCaseAndSeparators() {
        let code = String(symbols.dropLast(4)) + "ABCD"
        XCTAssertTrue(RecoveryKit.matchesRecoveryKeyEnding(code, typed: "ABCD"))
        XCTAssertTrue(RecoveryKit.matchesRecoveryKeyEnding(code, typed: "abcd"))
        XCTAssertTrue(RecoveryKit.matchesRecoveryKeyEnding(code, typed: "ab-cd"))
        XCTAssertTrue(RecoveryKit.matchesRecoveryKeyEnding(code, typed: " a b c d "))
        XCTAssertFalse(RecoveryKit.matchesRecoveryKeyEnding(code, typed: "ABCE"))
        XCTAssertFalse(RecoveryKit.matchesRecoveryKeyEnding(code, typed: "BCD"))
        XCTAssertFalse(RecoveryKit.matchesRecoveryKeyEnding(code, typed: "ABCDE"))
        XCTAssertFalse(RecoveryKit.matchesRecoveryKeyEnding(code, typed: ""))
    }

    // MARK: - Code input

    func testFormatGroupsSymbolsInBlocksOfFour() {
        XCTAssertEqual(RecoveryKit.formatRecoveryCode(""), "")
        XCTAssertEqual(RecoveryKit.formatRecoveryCode("7BQ"), "7BQ")
        XCTAssertEqual(RecoveryKit.formatRecoveryCode("7BQ2"), "7BQ2")
        XCTAssertEqual(RecoveryKit.formatRecoveryCode("7BQ2K"), "7BQ2-K")
        XCTAssertEqual(RecoveryKit.formatRecoveryCode(RecoveryKit.normalizeRecoveryCode(code.lowercased())), code)
    }

    func testNormalizeDropsSeparatorsAndMapsAmbiguousLetters() {
        XCTAssertEqual(RecoveryKit.normalizeRecoveryCode(" 7bq2-k9mx\tlo\n"), "7BQ2K9MX10")
        XCTAssertEqual(RecoveryKit.normalizeRecoveryCode("i"), "1")
    }

    // MARK: - Validation matrices

    func testUserIdValidationMatrix() {
        XCTAssertFalse(RecoveryKit.isValidUserId(""))
        XCTAssertTrue(RecoveryKit.isValidUserId(userId))
        var replaced = Array(userId)
        replaced[5] = "1"
        let invalid = [
            String(userId.dropLast()),
            userId + "a",
            "d" + String(userId.dropFirst()),
            String(userId.dropLast()) + "b",  // non-zero trailing bits
            String(replaced),  // not in the base32 alphabet
        ]
        for input in invalid {
            XCTAssertFalse(RecoveryKit.isValidUserId(input), "'\(input)'")
        }
    }

    func testRecoveryCodeValidationMatrix() {
        enum Expected { case incomplete, valid, broken }
        let cases: [(String, Expected)] = [
            ("", .incomplete),
            ("7BQ2-K9", .incomplete),
            (code, .valid),
            (code.lowercased(), .valid),
            // I/L -> 1, O -> 0, like gim-core's parser.
            (symbols.replacingOccurrences(of: "1", with: "l").replacingOccurrences(of: "0", with: "o"), .valid),
            (chunked(symbols, by: 5).joined(separator: " "), .valid),
            (symbols + "0", .broken),
            (String(symbols.dropLast()) + "U", .broken),
            (String(symbols.dropLast()) + "1", .broken),  // non-zero padding bits
            ("7BQ2!", .broken),
        ]
        for (input, expected) in cases {
            let normalized = RecoveryKit.normalizeRecoveryCode(input)
            XCTAssertEqual(RecoveryKit.isValidRecoveryCode(normalized), expected == .valid, "'\(input)'")
            XCTAssertEqual(RecoveryKit.isBrokenRecoveryCode(normalized), expected == .broken, "'\(input)'")
        }
    }

    // MARK: - Fake client

    func testFakeClientCodeRoundTrips() async throws {
        let client = try await FakeGimClientFactory(scheduler: ImmediateFakeScheduler())
            .make(config: ClientConfig(serverUrl: "http://localhost:8080"), hooks: TestPlatformHooks())
        let code = try await client.createIdentity(displayName: "Kit test")
        let normalized = RecoveryKit.normalizeRecoveryCode(code)
        XCTAssertTrue(RecoveryKit.isValidRecoveryCode(normalized))
        let userId = try XCTUnwrap(client.userId())
        let text = RecoveryKit.format(userId: userId, recoveryCode: code, labels: labels)
        XCTAssertTrue(text.contains("Account ID: \(userId)\n"))
        let parsed = RecoveryKit.parse(text)
        XCTAssertEqual(parsed.recoveryCode, normalized)
        // The demo client's ids ("user-local-1") are not gim-core user ids, so the parser cannot find one.
        XCTAssertEqual(parsed.userId, RecoveryKit.isValidUserId(userId) ? userId : nil)
        XCTAssertTrue(
            RecoveryKit.matchesRecoveryKeyEnding(code, typed: RecoveryKit.recoveryKeyEnding(code).lowercased()))
    }

    private func chunked(_ text: String, by size: Int) -> [String] {
        let characters = Array(text)
        return stride(from: 0, to: characters.count, by: size)
            .map { String(characters[$0..<min($0 + size, characters.count)]) }
    }
}
