import Foundation
import GIMClientKit
import GIMFeatures

/// Settings wording for GIMFeatures values whose own English text predates the glossary (hub, verified, home hub).
///
/// Maps the view models' states and fixed strings to keys of the `Settings` table.
enum SettingsText {
    /// Key of the state text of a server row.
    static func hubStateKey(_ state: HubState) -> String {
        switch state {
        case .verified: "settings.servers.connected"
        case .unverified: "settings.servers.notChecked"
        case .removed: "settings.servers.removed"
        }
    }

    /// Key of the alert title for a `HubsViewModel.Notice`, matched by the view model's English title; any other
    /// notice gets the generic "Can't remove this server".
    static func noticeKey(title: String) -> String {
        switch title {
        case "Can't Remove Home Hub": "settings.servers.cantRemoveMain"
        case "Can't Remove Last Hub": "settings.servers.cantRemoveLast"
        case "Try Again Later": "settings.servers.tryLater"
        default: "settings.servers.cantRemove"
        }
    }

    /// Key of the alert message for a known notice title; `nil` for the generic notice, which keeps the view model's
    /// message.
    static func noticeMessageKey(title: String) -> String? {
        switch noticeKey(title: title) {
        case "settings.servers.cantRemoveMain": "settings.servers.cantRemoveMainBody"
        case "settings.servers.cantRemoveLast": "settings.servers.cantRemoveLastBody"
        case "settings.servers.tryLater": "settings.servers.tryLaterBody"
        default: nil
        }
    }

    /// Key for an `AddHubViewModel.errorMessage` the add-server sheet expects; `nil` for unexpected errors, which are
    /// shown as they are.
    static func addServerErrorKey(_ message: String) -> String? {
        switch message {
        case ErrorPresenter.hubRefusedMessage: "settings.addServer.refused"
        case ErrorPresenter.message(for: GimError.HubNotVerified(reason: "")): "settings.addServer.notVerified"
        default: nil
        }
    }

    /// "This Mac" for this device, else "Device " and the first 8 characters of its id.
    static func deviceLabel(_ device: DeviceInfo) -> String {
        if device.isCurrent {
            return String(localized: "settings.devices.thisMac", table: "Settings")
        }
        let shortId = String(device.deviceId.prefix(8))
        return String(localized: "settings.devices.other", defaultValue: "Device \(shortId)", table: "Settings")
    }
}
