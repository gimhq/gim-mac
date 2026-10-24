import AppKit
import SwiftUI

/// The app's light or dark look, chosen in Settings.
enum AppearanceChoice: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    /// Picker title in the `Settings` table.
    var titleKey: LocalizedStringKey {
        switch self {
        case .system: "settings.appearance.system"
        case .light: "settings.appearance.light"
        case .dark: "settings.appearance.dark"
        }
    }

    /// Sets the appearance of the whole app, which every window follows.
    @MainActor
    static func apply(_ choice: AppearanceChoice) {
        switch choice {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
