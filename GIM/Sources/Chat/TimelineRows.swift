import GIMFeatures
import SwiftUI

/// One row of the timeline: a message, a day chip, a membership change or the typing row.
struct TimelineRowView: View {
    let item: TimelineDisplayItem
    let pane: ChatPaneModel

    var body: some View {
        switch item.kind {
        case .message(let row):
            MessageRowView(row: row, pane: pane)
        case .dateSeparator(let text):
            DateChipView(text: text)
                .padding(.vertical, DesignTokens.spacingS)
        case .membership(let text):
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacingS)
        case .typing(let text):
            Text(text)
                .font(.caption)
                .italic()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.spacingM)
                .padding(.vertical, DesignTokens.spacingXS)
        }
    }
}

/// The day a group of messages was sent, as a centred capsule.
struct DateChipView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, DesignTokens.spacingS)
            .padding(.vertical, 2)
            .background(ChatTheme.otherBubble, in: Capsule())
            .frame(maxWidth: .infinity)
    }
}

/// A message row: selectable by a click, with the message context menu.
private struct MessageRowView: View {
    let row: TimelineMessageRow
    let pane: ChatPaneModel

    private var isSelected: Bool {
        pane.selectedMessageId == row.message.messageId
    }

    var body: some View {
        MessageBubbleView(row: row, pane: pane)
            .padding(.horizontal, DesignTokens.spacingM)
            .padding(.vertical, 1)
            .background(isSelected ? ChatTheme.selectionBackground : Color.clear)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    pane.selectedMessageId = row.message.messageId
                }
            )
            .contextMenu {
                MessageContextMenu(row: row, pane: pane)
            }
            .padding(.bottom, TimelineRowLayout.spacingAfter(row: row))
    }
}

/// Menu items from `MessageActionsViewModel.actions(for:isReadOnly:)`, in its order.
private struct MessageContextMenu: View {
    let row: TimelineMessageRow
    let pane: ChatPaneModel

    var body: some View {
        let messageId = row.message.messageId
        ForEach(MessageActionsViewModel.actions(for: row.message, isReadOnly: pane.timeline.isReadOnly), id: \.self) {
            action in
            switch action {
            case .reply:
                Button {
                    pane.reply(to: messageId)
                } label: {
                    Text("chat.timeline.action.reply", tableName: "Chat")
                }
            case .react:
                Menu {
                    ForEach(MessageActionsViewModel.quickReactions, id: \.self) { emoji in
                        Button {
                            Task { await pane.toggleReaction(emoji, on: messageId) }
                        } label: {
                            Text(verbatim: emoji)
                        }
                    }
                } label: {
                    Text("chat.timeline.action.react", tableName: "Chat")
                }
            case .copy:
                Button {
                    pane.copy(messageId: messageId)
                } label: {
                    Text("chat.timeline.action.copy", tableName: "Chat")
                }
            case .edit:
                Button {
                    pane.edit(messageId: messageId)
                } label: {
                    Text("chat.timeline.action.edit", tableName: "Chat")
                }
            case .delete:
                Button(role: .destructive) {
                    pane.requestDelete(messageId: messageId)
                } label: {
                    Text("chat.timeline.action.delete", tableName: "Chat")
                }
            case .retry:
                Button {
                    Task { await pane.retry(messageId: messageId) }
                } label: {
                    Text("chat.timeline.action.retry", tableName: "Chat")
                }
            }
        }
    }
}
