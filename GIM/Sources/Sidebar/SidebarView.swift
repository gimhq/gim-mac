import GIMClientKit
import SwiftUI

/// The chat list with its selection, loading and empty states, and the connection state underneath.
struct SidebarView: View {
    @Bindable var model: SidebarModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        content
            .safeAreaInset(edge: .bottom) {
                Text(connectionKey, tableName: "App")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, DesignTokens.spacingXS)
                    .frame(maxWidth: .infinity)
            }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            placeholder {
                ProgressView()
                Text("app.sidebar.loading", tableName: "App")
            }
        } else if let errorMessage = model.errorMessage {
            placeholder {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
            }
        } else if model.rows.isEmpty {
            placeholder {
                Text("app.sidebar.empty", tableName: "App")
            }
        } else {
            List(model.rows, selection: $model.selectedChatId) { row in
                SidebarRowView(row: row)
                    .contextMenu {
                        Button {
                            openWindow(id: ChatWindowID.windowGroupID, value: ChatWindowID(chatId: row.id))
                        } label: {
                            Text("app.sidebar.openInNewWindow", tableName: "App")
                        }
                    }
            }
            .listStyle(.sidebar)
        }
    }

    private func placeholder(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(spacing: DesignTokens.spacingS) {
            content()
        }
        .foregroundStyle(.secondary)
        .padding(DesignTokens.spacingL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var connectionKey: LocalizedStringKey {
        switch model.connectionState {
        case .connected: "app.connection.connected"
        case .connecting: "app.connection.connecting"
        case .offline: "app.connection.offline"
        case .syncing: "app.connection.syncing"
        }
    }
}
