import XCTest

@testable import GIM

final class AccountIdTokenTests: XCTestCase {
    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz234567")

    /// "u", 54 base32 characters starting at `offset`, then `last`.
    private static func token(offset: Int = 0, last: Character = "a") -> String {
        "u" + String((0..<54).map { alphabet[($0 + offset) % alphabet.count] }) + String(last)
    }

    private let valid = AccountIdTokenTests.token()

    func testValidTokenHas56Characters() {
        XCTAssertEqual(valid.count, 56)
        XCTAssertTrue(AccountIdToken.isValid(valid))
    }

    func testExtractsFromPlainText() {
        XCTAssertEqual(AccountIdToken.extract(from: valid), valid)
        XCTAssertEqual(AccountIdToken.extract(from: "my id is \(valid) ok"), valid)
    }

    func testExtractsFromPunctuation() {
        XCTAssertEqual(AccountIdToken.extract(from: "id: \(valid)."), valid)
    }

    func testExtractsFromUrl() {
        XCTAssertEqual(AccountIdToken.extract(from: "gim://user/\(valid)?x=1"), valid)
    }

    func testRejectsWrongLengths() {
        XCTAssertNil(AccountIdToken.extract(from: String(valid.dropLast())))
        XCTAssertNil(AccountIdToken.extract(from: valid + "a"))
    }

    func testRejectsUppercase() {
        XCTAssertNil(AccountIdToken.extract(from: valid.uppercased()))
        XCTAssertNil(AccountIdToken.extract(from: "u" + valid.dropFirst().uppercased()))
    }

    func testRejectsLastCharacterOutsideAiqy() {
        XCTAssertNil(AccountIdToken.extract(from: Self.token(last: "b")))
        for last: Character in ["a", "i", "q", "y"] {
            XCTAssertNotNil(AccountIdToken.extract(from: Self.token(last: last)))
        }
    }

    func testRejectsDigitsOutsideBase32() {
        for digit in ["1", "0", "8", "9"] {
            let token = "u" + digit + valid.dropFirst(2)
            XCTAssertEqual(token.count, 56)
            XCTAssertNil(AccountIdToken.extract(from: token), digit)
        }
    }

    func testReturnsFirstValidToken() {
        let second = Self.token(offset: 5, last: "q")
        XCTAssertEqual(AccountIdToken.extract(from: "\(valid) and \(second)"), valid)
        XCTAssertEqual(AccountIdToken.extract(from: "bad u123 then \(second), \(valid)"), second)
    }

    func testEmptyTextHasNoToken() {
        XCTAssertNil(AccountIdToken.extract(from: ""))
    }
}
