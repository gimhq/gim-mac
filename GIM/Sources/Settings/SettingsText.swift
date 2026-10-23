import Foundation
import GIMClientKit

/// Settings wording for values GIMFeatures has no text for.
enum SettingsText {
    /// "This Mac" for this device, else "Device " and the first 8 characters of its id.
    static func deviceLabel(_ device: DeviceInfo) -> String {
        if device.isCurrent {
            return String(localized: "settings.devices.thisMac", table: "Settings")
        }
        let shortId = String(device.deviceId.prefix(8))
        return String(localized: "settings.devices.other", defaultValue: "Device \(shortId)", table: "Settings")
    }
}
