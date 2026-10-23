import AppKit
import GIMClientKit
import SwiftUI

/// The menu of the menu bar extra: recent chats, then open, settings and quit.
struct MenuBarExtraContent: View {
    let model: AppModel
    let system: SystemServices

    private static let maxChats = 8

    var body: some View {
        if model.phase == .ready {
            let chats = recentChats
            if chats.isEmpty {
                Text("settings.menuBar.noChats", tableName: "Settings")
            } else {
                ForEach(chats, id: \.chatId) { chat in
                    Button {
                        system.router.openChat(chat.chatId)
                    } label: {
                        Text(title(for: chat))
                    }
                }
            }
            Divider()
            openButton
            SettingsLink {
                Text("settings.menuBar.settings", tableName: "Settings")
            }
            Divider()
        } else {
            openButton
        }
        Button {
            NSApp.terminate(nil)
        } label: {
            Text("settings.menuBar.quit", tableName: "Settings")
        }
        .keyboardShortcut("q")
    }

    private var openButton: some View {
        Button {
            system.router.showMainWindow()
        } label: {
            Text("settings.menuBar.open", tableName: "Settings")
        }
    }

    /// Most recently updated first.
    private var recentChats: [ChatSummary] {
        Array(system.unread.chats.sorted { $0.updatedAtMs > $1.updatedAtMs }.prefix(Self.maxChats))
    }

    private func title(for chat: ChatSummary) -> String {
        guard chat.unreadCount > 0 else { return chat.name }
        let name = chat.name
        let count = Int(chat.unreadCount)
        return String(localized: "settings.menuBar.chatUnread", defaultValue: "\(name) (\(count))", table: "Settings")
    }
}
