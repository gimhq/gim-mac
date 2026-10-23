import XCTest

@testable import GIM

final class SettingsSectionTests: XCTestCase {
    func testSectionsAreInSidebarOrder() {
        XCTAssertEqual(
            SettingsSection.allCases,
            [.profile, .accountDevices, .notifications, .appearance, .language, .advanced, .helpAbout])
        XCTAssertEqual(SettingsSection.allCases.count, 7)
        XCTAssertEqual(SettingsSection.accountDevices.titleKey, "settings.section.accountDevices")
    }

    func testEverySectionTitleHasAnEnglishValue() {
        for section in SettingsSection.allCases {
            let value = String(localized: String.LocalizationValue(section.titleKey), table: "Settings")
            XCTAssertNotEqual(value, section.titleKey, section.titleKey)
        }
    }

    func testAccountSafetyIsHidden() {
        XCTAssertFalse(SettingsFeatureFlags.accountSafety)
    }
}
