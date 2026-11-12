import LocalAuthentication
import XCTest

@testable import GIM

final class MacDeviceAuthenticatorTests: XCTestCase {
    func testMapsLocalAuthenticationErrors() {
        XCTAssertEqual(MacDeviceAuthenticator.result(for: LAError(.userCancel)), .cancelled)
        XCTAssertEqual(MacDeviceAuthenticator.result(for: LAError(.systemCancel)), .cancelled)
        XCTAssertEqual(MacDeviceAuthenticator.result(for: LAError(.passcodeNotSet)), .unavailable)
        XCTAssertEqual(MacDeviceAuthenticator.result(for: LAError(.authenticationFailed)), .failed)
        XCTAssertEqual(MacDeviceAuthenticator.result(for: nil), .failed)
    }
}
