import AppKit
import Combine
import SwiftUI

/// A chat pane: header, timeline, error banner and the bottom bar. `init(title:)` is the placeholder the app shell
/// still shows.
struct ChatPaneView: View {
    private enum Content {
        case placeholder(title: String)
        case chat(model: AppModel, chatId: String)
    }

    private let content: Content
    @State private var pane: ChatPaneModel?

    /// The real pane for `chatId` on the signed-in client.
    init(model: AppModel, chatId: String) {
        content = .chat(model: model, chatId: chatId)
    }

    /// Placeholder with the chat's title.
    init(title: String) {
        content = .placeholder(title: title)
    }

    var body: some View {
        switch content {
        case .placeholder(let title):
            placeholder(title: title)
        case .chat(let model, let chatId):
            chat(model: model, chatId: chatId)
        }
    }

    private func placeholder(title: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text("chat.placeholder.comingSoon", tableName: "Chat")
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func chat(model: AppModel, chatId: String) -> some View {
        Group {
            if let pane {
                VStack(spacing: 0) {
                    ChatPaneHeader(pane: pane)
                    Divider()
                    TimelineListView(pane: pane)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if let errorMessage = pane.errorMessage {
                        ErrorBanner(message: errorMessage) { pane.dismissError() }
                    }
                    Divider()
                    ComposerView(pane: pane)
                }
            } else if model.client == nil {
                Text("chat.placeholder.comingSoon", tableName: "Chat")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
            }
        }
        .frame(minWidth: ChatTheme.paneMinWidth)
        .focusedSceneValue(\.chatPane, pane)
        .task(id: chatId) {
            pane?.stop()
            guard let client = model.client else {
                pane = nil
                return
            }
            let newPane = ChatPaneModel(client: client, chatId: chatId, ownUserId: model.session?.userId)
            newPane.isAppActive = NSApplication.shared.isActive
            newPane.start()
            pane = newPane
        }
        .onDisappear {
            pane?.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            setAppActive(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            setAppActive(false)
        }
    }

    private func setAppActive(_ isActive: Bool) {
        guard let pane else { return }
        pane.isAppActive = isActive
        Task { await pane.markReadIfNeeded() }
    }
}

/// Avatar, title, the typing line and the chat info button.
private struct ChatPaneHeader: View {
    @Bindable var pane: ChatPaneModel

    var body: some View {
        HStack(spacing: DesignTokens.spacingS) {
            AvatarView(
                initials: SidebarRowModel.initials(for: pane.title),
                colorIndex: SidebarRowModel.colorIndex(for: pane.chatId),
                accessibilityTitle: pane.title,
                size: ChatTheme.headerAvatarSize)
            VStack(alignment: .leading, spacing: 0) {
                Text(pane.title)
                    .font(.headline)
                    .lineLimit(1)
                if let subtitle = pane.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Button {
                pane.showsGroupInfo.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(Text("chat.pane.info", tableName: "Chat"))
            .accessibilityLabel(Text("chat.pane.info", tableName: "Chat"))
            .popover(isPresented: $pane.showsGroupInfo, arrowEdge: .bottom) {
                GroupInfoView(client: pane.client, chatId: pane.timeline.chatId)
            }
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.spacingS)
    }
}

/// An error from the chat with a button to hide it.
private struct ErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.spacingS) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            Text(message)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: dismiss) {
                Text("chat.pane.dismissError", tableName: "Chat")
            }
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.spacingS)
        .background(.bar)
    }
}
