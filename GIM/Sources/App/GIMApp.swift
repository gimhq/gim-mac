import SwiftUI

@main
struct GIMApp: App {
    @State private var model: AppModel
    @State private var system: SystemServices

    init() {
        let model = AppModel()
        _model = State(initialValue: model)
        _system = State(initialValue: SystemServices(model: model))
    }

    var body: some Scene {
        WindowGroup(id: ChatRouter.mainWindowGroupID) {
            RootView(model: model)
                .task { system.start() }
        }
        .commands {
            AppCommands()
        }

        WindowGroup(id: ChatWindowID.windowGroupID, for: ChatWindowID.self) { $chatWindow in
            if let chatWindow {
                ChatWindowView(model: model, chatWindow: chatWindow)
            }
        }

        Settings {
            SettingsScene(model: model, system: system)
        }

        MenuBarExtra(isInserted: $model.showsMenuBarExtra) {
            MenuBarExtraContent(model: model, system: system)
        } label: {
            MenuBarExtraLabel(system: system)
        }
        .menuBarExtraStyle(.menu)
    }
}
