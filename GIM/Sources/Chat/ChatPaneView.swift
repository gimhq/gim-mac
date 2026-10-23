import AppKit
import Combine
import SwiftUI

/// A chat pane: header, timeline, error banner and the bottom bar.
struct ChatPaneView: View {
    let model: AppModel
    let chatId: String
    @State private var pane: ChatPaneModel?

    var body: some View {
        Group {
            if let pane {
                VStack(spacing: 0) {
                    ChatPaneHeader(pane: pane)
                    Divider()
                    if pane.search.isActive {
                        ChatSearchBar(pane: pane)
                        Divider()
                    }
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
        .onChange(of: pane?.timeline.items) {
            pane?.updateSearch()
        }
        .onChange(of: pane?.search.query) {
            pane?.updateSearch()
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
