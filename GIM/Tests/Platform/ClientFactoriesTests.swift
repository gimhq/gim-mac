import Foundation
import GIMClientKit
import XCTest

@testable import GIM

final class ClientFactoriesTests: XCTestCase {
    func testDefaultIsGIMCore() {
        XCTAssertTrue(ClientFactories.default(defaults: makeTestDefaults()) is RealGimClientFactory)
    }

    func testFakeCoreLaunchArgumentSelectsTheDemoClientInDebug() {
        let defaults = makeTestDefaults()
        defaults.set(true, forKey: ClientFactories.useFakeCoreKey)
        #if DEBUG
            XCTAssertTrue(ClientFactories.default(defaults: defaults) is CoreGimClientFactory)
        #else
            XCTAssertTrue(ClientFactories.default(defaults: defaults) is RealGimClientFactory)
        #endif
    }
}
