import Foundation
import Observation

/// The app-wide system settings, kept in `UserDefaults`; every change is written immediately.
@MainActor
@Observable
final class SystemPreferences {
    nonisolated static let appearanceKey = "gim.appearance"
    nonisolated static let menuBarModeKey = "gim.menuBar.enabled"
    nonisolated static let hideDockIconKey = "gim.dock.hidden"
    nonisolated static let notificationSoundsKey = "gim.notifications.sounds"
    nonisolated static let showsBadgeKey = "gim.notifications.badge"
    nonisolated static let notificationsRequestedKey = "gim.notifications.requested"

    var appearance: AppearanceChoice {
        didSet { defaults.set(appearance.rawValue, forKey: Self.appearanceKey) }
    }
    /// Shows the menu bar extra.
    var menuBarMode: Bool {
        didSet { defaults.set(menuBarMode, forKey: Self.menuBarModeKey) }
    }
    /// Hides the Dock icon; only applied while `menuBarMode` is on.
    var hideDockIcon: Bool {
        didSet { defaults.set(hideDockIcon, forKey: Self.hideDockIconKey) }
    }
    var notificationSounds: Bool {
        didSet { defaults.set(notificationSounds, forKey: Self.notificationSoundsKey) }
    }
    /// Shows the unread count on the Dock icon.
    var showsBadge: Bool {
        didSet { defaults.set(showsBadge, forKey: Self.showsBadgeKey) }
    }
    /// Notification permission was asked for once; the system remembers the answer.
    var notificationsRequested: Bool {
        didSet { defaults.set(notificationsRequested, forKey: Self.notificationsRequestedKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = defaults.string(forKey: Self.appearanceKey).flatMap(AppearanceChoice.init(rawValue:)) ?? .system
        menuBarMode = defaults.object(forKey: Self.menuBarModeKey) as? Bool ?? false
        hideDockIcon = defaults.object(forKey: Self.hideDockIconKey) as? Bool ?? false
        notificationSounds = defaults.object(forKey: Self.notificationSoundsKey) as? Bool ?? true
        showsBadge = defaults.object(forKey: Self.showsBadgeKey) as? Bool ?? true
        notificationsRequested = defaults.object(forKey: Self.notificationsRequestedKey) as? Bool ?? false
    }
}
