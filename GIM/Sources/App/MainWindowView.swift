import SwiftUI

/// The signed-in layout: the sidebar and the selected chat's pane.
struct MainWindowView: View {
    let model: AppModel

    var body: some View {
        if let sidebar = model.sidebar {
            NavigationSplitView {
                SidebarView(model: sidebar)
                    .chatStartActions(model: model)
                    .navigationSplitViewColumnWidth(min: 240, ideal: 300)
            } detail: {
                if let id = model.selectedChatId {
                    ChatPaneView(model: model, chatId: id)
                } else {
                    Text("app.main.noChatSelected", tableName: "App")
                        .foregroundStyle(.secondary)
                }
            }
            .focusedSceneValue(\.sidebarModel, sidebar)
        }
    }
}
