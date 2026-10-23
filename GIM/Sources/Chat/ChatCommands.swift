import SwiftUI

extension FocusedValues {
    /// The focused window's chat pane, for `ChatCommands`.
    @Entry var chatPane: ChatPaneModel?
}

/// File menu items to start chats, and the Chat menu acting on the focused chat pane.
struct ChatCommands: Commands {
    @FocusedValue(\.chatPane) private var pane
    @FocusedValue(\.chatStarter) private var starter

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button {
                starter?.showNewChat()
            } label: {
                Text("chat.command.newChat", tableName: "Chat")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(starter == nil)

            Button {
                starter?.showNewGroup()
            } label: {
                Text("chat.command.newGroup", tableName: "Chat")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift, .option])
            .disabled(starter == nil)
        }

        CommandMenu(Text("chat.command.menu", tableName: "Chat")) {
            Button {
                guard let pane else { return }
                Task { await pane.send() }
            } label: {
                Text("chat.command.send", tableName: "Chat")
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(pane?.composer.canSend != true)

            Button {
                pane?.replyToSelected()
            } label: {
                Text("chat.command.reply", tableName: "Chat")
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(pane?.selectedMessageId == nil)

            Button {
                pane?.editLastOwnMessage()
            } label: {
                Text("chat.command.editLast", tableName: "Chat")
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(pane == nil)

            Divider()

            Button {
                pane?.showsGroupInfo.toggle()
            } label: {
                Text("chat.command.groupInfo", tableName: "Chat")
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(pane?.isGroup != true)

            // Find and Quick Look items are added by later subtasks.
        }
    }
}
