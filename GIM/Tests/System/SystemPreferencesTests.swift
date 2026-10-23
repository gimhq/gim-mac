import XCTest

@testable import GIM

@MainActor
final class SystemPreferencesTests: XCTestCase {
    func testDefaults() {
        let preferences = SystemPreferences(defaults: makeTestDefaults())
        XCTAssertEqual(preferences.appearance, .system)
        XCTAssertFalse(preferences.menuBarMode)
        XCTAssertFalse(preferences.hideDockIcon)
        XCTAssertTrue(preferences.notificationSounds)
        XCTAssertTrue(preferences.showsBadge)
        XCTAssertFalse(preferences.notificationsRequested)
    }

    func testChangesPersist() {
        let defaults = makeTestDefaults()
        let preferences = SystemPreferences(defaults: defaults)
        preferences.appearance = .dark
        preferences.menuBarMode = true
        preferences.hideDockIcon = true
        preferences.notificationSounds = false
        preferences.showsBadge = false
        preferences.notificationsRequested = true

        let reloaded = SystemPreferences(defaults: defaults)
        XCTAssertEqual(reloaded.appearance, .dark)
        XCTAssertTrue(reloaded.menuBarMode)
        XCTAssertTrue(reloaded.hideDockIcon)
        XCTAssertFalse(reloaded.notificationSounds)
        XCTAssertFalse(reloaded.showsBadge)
        XCTAssertTrue(reloaded.notificationsRequested)
        XCTAssertEqual(defaults.string(forKey: SystemPreferences.appearanceKey), "dark")
    }
}
