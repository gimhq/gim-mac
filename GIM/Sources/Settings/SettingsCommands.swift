import SwiftUI

/// Settings menu commands: "Settings…" (⌘,) opens the Settings window.
struct SettingsCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            SettingsLink {
                Text("settings.command.open", tableName: "Settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
