import SwiftUI

extension FocusedValues {
    /// The sidebar of the focused main window, for `ShellCommands`.
    @Entry var sidebarModel: SidebarModel?
}

/// View menu commands that act on the focused window's sidebar: open the selection in a new window, move the
/// selection, jump to a chat by number. New window, close and settings come from SwiftUI's default commands.
struct ShellCommands: Commands {
    @FocusedValue(\.sidebarModel) private var sidebar
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button {
                guard let chatId = sidebar?.selectedChatId else { return }
                openWindow(id: ChatWindowID.windowGroupID, value: ChatWindowID(chatId: chatId))
            } label: {
                Text("app.command.openInNewWindow", tableName: "App")
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .disabled(sidebar?.selectedChatId == nil)

            Divider()

            Button {
                sidebar?.selectNext()
            } label: {
                Text("app.command.nextChat", tableName: "App")
            }
            .keyboardShortcut(.downArrow, modifiers: [.command, .option])

            Button {
                sidebar?.selectPrevious()
            } label: {
                Text("app.command.previousChat", tableName: "App")
            }
            .keyboardShortcut(.upArrow, modifiers: [.command, .option])

            Divider()

            ForEach(1..<10, id: \.self) { number in
                Button {
                    sidebar?.select(index: number - 1)
                } label: {
                    Text(String(localized: "app.command.selectChat", defaultValue: "Chat \(number)", table: "App"))
                }
                .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: .command)
            }
        }
    }
}
