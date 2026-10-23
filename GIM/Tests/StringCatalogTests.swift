import XCTest

@testable import GIM

/// Every key the app uses has an English value in its String Catalog.
///
/// The catalogs are compiled into the app at build time, so the test resolves a static list of keys through the
/// test host's `Bundle.main` instead of parsing the `.xcstrings` files. Keep the map in sync with
/// `GIM/Resources/*.xcstrings`; W5's language test will replace it with a catalog-parsing test.
final class StringCatalogTests: XCTestCase {
    static let keysByTable: [String: [String]] = [
        "App": [
            "app.launch.loading",
            "app.launch.tryAgain",
            "app.ready.placeholder",
            "app.menuBar.placeholder",
        ],
        "Explainer": [
            "explainer.title",
            "explainer.intro.body",
            "explainer.noPhoneNumber.title",
            "explainer.noPhoneNumber.body",
            "explainer.onYourDevices.title",
            "explainer.onYourDevices.body",
            "explainer.lockedMessages.title",
            "explainer.lockedMessages.body",
            "explainer.accountId.title",
            "explainer.accountId.body",
            "explainer.recoveryKey.title",
            "explainer.recoveryKey.body",
        ],
        "Onboarding": [
            "onboarding.demo.displayName",
            "onboarding.demo.start",
            "onboarding.welcome.body",
            "onboarding.welcome.title",
        ],
        "Chat": [
            "chat.placeholder.comingSoon",
        ],
        "Settings": [
            "settings.window.title",
        ],
    ]

    func testEveryKeyHasAnEnglishValue() {
        for (table, keys) in Self.keysByTable {
            for key in keys {
                // `localizedString(forKey:value:table:)` returns the raw format string, so keys with `%@` placeholders
                // resolve without `String(format:)` consuming missing arguments; a missing key comes back unchanged.
                let value = Bundle.main.localizedString(forKey: key, value: nil, table: table)
                XCTAssertFalse(value.isEmpty, "\(table): \(key) is empty")
                XCTAssertNotEqual(value, key, "\(table): \(key) has no English value")
            }
        }
    }

    func testEveryTableIsCovered() {
        XCTAssertEqual(Set(Self.keysByTable.keys), ["App", "Explainer", "Onboarding", "Chat", "Settings"])
    }
}
