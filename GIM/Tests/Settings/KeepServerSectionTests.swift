import Foundation
import GIMFeatures
import XCTest

@testable import GIM

/// `KeepServerViewModel` as the Settings → Advanced Keep server section uses it, and the section's strings.
@MainActor
final class KeepServerSectionTests: XCTestCase {
    private static let defaultUrl = "https://keep.example.test"

    private func makeKeep(defaults: UserDefaults = makeTestDefaults()) -> KeepServerViewModel {
        KeepServerViewModel(defaults: defaults, defaultUrl: Self.defaultUrl, activeUrl: Self.defaultUrl)
    }

    func testOffThenOnReturnsToTheDefault() {
        let keep = makeKeep()
        keep.setOn(false)
        XCTAssertFalse(keep.isOn)
        XCTAssertEqual(keep.setting, .off)

        keep.setOn(true)
        XCTAssertTrue(keep.isOn)
        XCTAssertEqual(keep.setting, .automatic)
        XCTAssertEqual(keep.url, Self.defaultUrl)
        XCTAssertTrue(keep.isDefault)
    }

    func testSaveRefusesHttpOutsideTheLocalNetwork() {
        let defaults = makeTestDefaults()
        let keep = makeKeep(defaults: defaults)
        keep.draft = "http://example.com"

        XCTAssertFalse(keep.save())
        XCTAssertEqual(keep.errorKind, .notSecure)
        XCTAssertEqual(keep.setting, .automatic)
        XCTAssertNil(defaults.string(forKey: KeepServer.settingKey))
    }

    func testSaveAcceptsHttpOnTheLocalNetwork() {
        let defaults = makeTestDefaults()
        let keep = makeKeep(defaults: defaults)
        keep.draft = "http://192.168.1.10:8080"

        XCTAssertTrue(keep.save())
        XCTAssertNil(keep.errorKind)
        XCTAssertEqual(keep.setting, .custom("http://192.168.1.10:8080"))
        XCTAssertEqual(KeepServer.load(from: defaults), .custom("http://192.168.1.10:8080"))
    }

    func testResetStoresAutomatic() {
        let defaults = makeTestDefaults()
        let keep = makeKeep(defaults: defaults)
        keep.draft = "https://keep.other.test"
        XCTAssertTrue(keep.save())
        XCTAssertFalse(keep.isDefault)

        keep.resetToDefault()
        XCTAssertEqual(keep.setting, .automatic)
        XCTAssertEqual(keep.draft, Self.defaultUrl)
        XCTAssertNil(defaults.string(forKey: KeepServer.settingKey))
        XCTAssertEqual(KeepServer.load(from: defaults), .automatic)
    }

    func testNeedsRestartAfterAChangeAndNotAfterResettingToTheActiveDefault() {
        let keep = makeKeep()
        XCTAssertFalse(keep.needsRestart)

        keep.draft = "https://keep.other.test"
        XCTAssertTrue(keep.save())
        XCTAssertTrue(keep.needsRestart)

        keep.resetToDefault()
        XCTAssertFalse(keep.needsRestart)

        keep.setOn(false)
        XCTAssertTrue(keep.needsRestart)
    }

    func testEveryKeepKeyIsInEveryLanguage() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Settings.xcstrings")
        let catalog = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        let expected: Set = [
            "settings.keep.address", "settings.keep.default", "settings.keep.footer", "settings.keep.restart",
            "settings.keep.restartNeeded", "settings.keep.save", "settings.keep.title", "settings.keep.toggle",
            "settings.keep.useDefault",
        ]
        XCTAssertEqual(Set(strings.keys.filter { $0.hasPrefix("settings.keep.") }), expected)
        for key in expected.sorted() {
            let entry = strings[key] as? [String: Any]
            let localizations = entry?["localizations"] as? [String: Any] ?? [:]
            for language in LanguageTablesTests.languages {
                let unit = (localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any]
                XCTAssertEqual(unit?["state"] as? String, "translated", "\(key) [\(language)]")
                XCTAssertFalse((unit?["value"] as? String ?? "").isEmpty, "\(key) [\(language)]")
            }
        }
    }
}
