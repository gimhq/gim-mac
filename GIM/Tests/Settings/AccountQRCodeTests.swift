import XCTest

@testable import GIM

final class AccountQRCodeTests: XCTestCase {
    func testPayloadIsTheBareAccountId() {
        XCTAssertEqual(AccountQRCode.payload(accountId: "user-alex"), "user-alex")
        XCTAssertEqual(AccountQRCode.payload(accountId: " user-alex\n"), " user-alex\n")
    }

    func testImageForDemoAccountId() throws {
        let image = try XCTUnwrap(AccountQRCode.image(payload: AccountQRCode.payload(accountId: "user-alex"), side: 240))
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertEqual(image.size.width, image.size.height)
    }
}
