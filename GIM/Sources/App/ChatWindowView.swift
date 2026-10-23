import SwiftUI

/// Content of a chat opened in its own window.
struct ChatWindowView: View {
    let model: AppModel
    let chatWindow: ChatWindowID

    var body: some View {
        let title = model.sidebar?.title(for: chatWindow.chatId) ?? chatWindow.chatId
        ChatPaneView(title: title)
            .navigationTitle(title)
            .frame(minWidth: 480, minHeight: 360)
    }
}
