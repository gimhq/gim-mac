import SwiftUI

@main
struct GIMApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
        .commands {
            AppCommands()
        }

        Settings {
            SettingsScene()
        }

        // Menu bar mode is off until a later subtask implements it.
        MenuBarExtra(isInserted: $model.showsMenuBarExtra) {
            Text("app.menuBar.placeholder", tableName: "App")
        } label: {
            Label {
                Text("app.menuBar.placeholder", tableName: "App")
            } icon: {
                Image(systemName: "bubble.left.and.bubble.right")
            }
        }
    }
}
