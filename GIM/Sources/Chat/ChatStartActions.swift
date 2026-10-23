import SwiftUI

extension FocusedValues {
    /// The main window's chat starter; read by the New chat and New group menu items.
    @Entry var chatStarter: ChatStarter?
}

extension View {
    /// Adds the New chat and New group toolbar buttons, their sheets and the `chatStarter` focused value.
    func chatStartActions(model: AppModel) -> some View {
        modifier(ChatStartActionsModifier(model: model))
    }
}

private struct ChatStartActionsModifier: ViewModifier {
    let model: AppModel
    @State private var starter: ChatStarter?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        starter?.showNewChat()
                    } label: {
                        Label {
                            Text("chat.new.toolbar.newChat", tableName: "Chat")
                        } icon: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                    .help(Text("chat.new.toolbar.newChat", tableName: "Chat"))
                    .accessibilityLabel(Text("chat.new.toolbar.newChat", tableName: "Chat"))
                    .disabled(starter == nil)

                    Button {
                        starter?.showNewGroup()
                    } label: {
                        Label {
                            Text("chat.new.toolbar.newGroup", tableName: "Chat")
                        } icon: {
                            Image(systemName: "person.2.badge.plus")
                        }
                    }
                    .help(Text("chat.new.toolbar.newGroup", tableName: "Chat"))
                    .accessibilityLabel(Text("chat.new.toolbar.newGroup", tableName: "Chat"))
                    .disabled(starter == nil)
                }
            }
            .sheet(item: sheet) { sheet in
                if let starter {
                    switch sheet {
                    case .newChat: NewChatSheet(starter: starter)
                    case .newGroup: NewGroupSheet(starter: starter)
                    }
                }
            }
            .focusedSceneValue(\.chatStarter, starter)
            .onAppear {
                guard starter == nil, let client = model.client else { return }
                starter = ChatStarter(client: client) { [model] chatId in model.selectedChatId = chatId }
            }
    }

    private var sheet: Binding<ChatStarter.Sheet?> {
        Binding(get: { starter?.sheet }, set: { starter?.sheet = $0 })
    }
}
