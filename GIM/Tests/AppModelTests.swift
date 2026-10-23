import GIMClientKit
import XCTest

@testable import GIM

@MainActor
final class AppModelTests: XCTestCase {
    func testStartWithoutIdentityShowsOnboarding() async {
        let model = makeTestModel()
        await model.start()
        XCTAssertEqual(model.phase, .onboarding)
        XCTAssertNil(model.session)
        XCTAssertNil(model.launchError)
    }

    func testCreateDemoIdentitySignsInAndRemembersServer() async throws {
        let defaults = makeTestDefaults()
        let model = makeTestModel(defaults: defaults)
        await model.start()
        try await model.createDemoIdentity(displayName: "Demo user")
        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.session?.displayName, "Demo user")
        XCTAssertEqual(model.serverUrl, "http://localhost:8080")
        XCTAssertEqual(defaults.string(forKey: AppModel.serverUrlKey), "http://localhost:8080")
    }

    func testResolvedServerUrlPrecedence() {
        let defaults = makeTestDefaults()
        let model = makeTestModel(defaults: defaults)
        XCTAssertEqual(model.resolvedServerUrl(), "http://localhost:8080")

        defaults.set("http://argument.test", forKey: AppModel.defaultServerUrlKey)
        XCTAssertEqual(model.resolvedServerUrl(), "http://argument.test")

        defaults.set("http://last.test", forKey: AppModel.serverUrlKey)
        XCTAssertEqual(model.resolvedServerUrl(), "http://last.test")

        let unbundled = makeTestModel(defaults: makeTestDefaults(), bundledServerUrl: nil)
        XCTAssertEqual(unbundled.resolvedServerUrl(), AppModel.builtInServerUrl)
    }
}
