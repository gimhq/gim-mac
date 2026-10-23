import XCTest

@testable import GIM

final class LanguagePreferenceTests: XCTestCase {
    private var suite = ""
    private var defaults: UserDefaults!

    override func setUp() {
        suite = "im.g.mac.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testUnsetIsSystem() {
        XCTAssertEqual(LanguagePreference.choice(in: defaults, domain: suite), .system)
    }

    func testApplyThenChoiceRoundTrips() {
        for choice in LanguageChoice.allCases {
            LanguagePreference.apply(choice, to: defaults)
            XCTAssertEqual(LanguagePreference.choice(in: defaults, domain: suite), choice)
        }
    }

    func testSystemRemovesTheKey() {
        LanguagePreference.apply(.es, to: defaults)
        XCTAssertEqual(defaults.persistentDomain(forName: suite)?[LanguagePreference.key] as? [String], ["es"])
        LanguagePreference.apply(.system, to: defaults)
        XCTAssertNil(defaults.persistentDomain(forName: suite)?[LanguagePreference.key])
    }

    func testRegionCodesMap() {
        XCTAssertEqual(LanguageChoice(languageCode: "zh-CN"), .zhHans)
        XCTAssertEqual(LanguageChoice(languageCode: "zh-TW"), .zhHant)
        XCTAssertEqual(LanguageChoice(languageCode: "en-GB"), .en)
        XCTAssertNil(LanguageChoice(languageCode: "fr"))

        defaults.set(["fr"], forKey: LanguagePreference.key)
        XCTAssertEqual(LanguagePreference.choice(in: defaults, domain: suite), .system)
    }
}
