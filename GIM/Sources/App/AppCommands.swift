import SwiftUI

/// The app's menu commands, composed from one `Commands` type per feature.
struct AppCommands: Commands {
    var body: some Commands {
        ShellCommands()
        ChatCommands()
        SettingsCommands()
    }
}
