import SwiftUI

/// Placeholder settings window. Replaced by the settings workstream.
struct SettingsScene: View {
    var body: some View {
        Text("settings.window.title", tableName: "Settings")
            .frame(width: 480, height: 320)
            .navigationTitle(Text("settings.window.title", tableName: "Settings"))
    }
}
