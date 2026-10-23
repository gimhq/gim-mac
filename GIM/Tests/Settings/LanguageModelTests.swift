import XCTest

@testable import GIM

@MainActor
final class LanguageModelTests: XCTestCase {
    private var suite = ""
    private var defaults: UserDefaults!

    override func setUp() async throws {
        suite = "im.g.mac.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
    }

    func testFreshSuiteStartsOnSystem() {
        let language = LanguageModel(defaults: defaults, domain: suite)
        XCTAssertEqual(language.choice, .system)
        XCTAssertEqual(language.launchChoice, .system)
        XCTAssertFalse(language.needsRelaunch)
    }

    func testSelectPersistsAndNeedsRelaunch() {
        let language = LanguageModel(defaults: defaults, domain: suite)
        language.select(.zhHans)

        XCTAssertEqual(language.choice, .zhHans)
        XCTAssertTrue(language.needsRelaunch)
        XCTAssertEqual(defaults.persistentDomain(forName: suite)?[LanguagePreference.key] as? [String], ["zh-Hans"])
        XCTAssertEqual(LanguageModel(defaults: defaults, domain: suite).choice, .zhHans)
    }

    func testSelectingTheLaunchLanguageAgainNeedsNoRelaunch() {
        let language = LanguageModel(defaults: defaults, launchChoice: .es, domain: suite)
        language.select(.en)
        XCTAssertTrue(language.needsRelaunch)
        language.select(.es)
        XCTAssertFalse(language.needsRelaunch)
    }

    func testSelectingSystemRemovesTheKey() {
        let language = LanguageModel(defaults: defaults, domain: suite)
        language.select(.es)
        language.select(.system)

        XCTAssertEqual(language.choice, .system)
        XCTAssertFalse(language.needsRelaunch)
        XCTAssertNil(defaults.persistentDomain(forName: suite)?[LanguagePreference.key])
    }
}
