import Foundation
import Observation
import ServiceManagement

/// Starts gim when the person logs in to the Mac, through `SMAppService.mainApp`.
@MainActor
@Observable
final class LaunchAtLoginController {
    private(set) var isEnabled = false
    /// Registered, but the person still has to allow it in System Settings > General > Login Items.
    private(set) var requiresApproval = false
    private(set) var errorMessage: String?

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        requiresApproval = status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = String(localized: "settings.launchAtLogin.failed", table: "Settings")
        }
        refresh()
    }

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
