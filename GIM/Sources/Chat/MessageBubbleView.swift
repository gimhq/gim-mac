import GIMClientKit
import GIMFeatures
import SwiftUI

/// One message: avatar and sender name in groups, the bubble with reply quote, body and footer, and the reactions.
struct MessageBubbleView: View {
    let row: TimelineMessageRow
    let pane: ChatPaneModel

    private var horizontalAlignment: HorizontalAlignment {
        TimelineRowLayout.alignment(for: row)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacingS) {
            if row.isOwn {
                Spacer(minLength: DesignTokens.spacingL * 4)
            } else if pane.timeline.isGroup {
                avatar
            }
            VStack(alignment: horizontalAlignment, spacing: 2) {
                if TimelineRowLayout.showsSenderName(row: row), let senderName = row.senderName {
                    Text(senderName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                bubble
                if !row.reactions.isEmpty {
                    reactions
                }
            }
            .frame(
                maxWidth: ChatTheme.maxBubbleWidth, alignment: Alignment(horizontal: horizontalAlignment, vertical: .top)
            )
            if !row.isOwn {
                Spacer(minLength: DesignTokens.spacingL * 4)
            }
        }
        .background(searchBackground)
    }

    /// Find in chat: a light background on matches, a stronger one on the current match.
    private var searchBackground: Color {
        let messageId = row.message.messageId
        if pane.search.currentMatchId == messageId { return ChatTheme.searchCurrentMatchBackground }
        if pane.search.matchIds.contains(messageId) { return ChatTheme.searchMatchBackground }
        return .clear
    }

    /// The sender's avatar on the first row of a run; the same space otherwise, so bubbles line up.
    @ViewBuilder
    private var avatar: some View {
        if TimelineRowLayout.showsAvatar(row: row, isGroup: pane.timeline.isGroup) {
            let sender = row.message.sender
            let name = UserLabel.name(for: sender)
            AvatarView(
                initials: SidebarRowModel.initials(for: name),
                colorIndex: SidebarRowModel.colorIndex(for: sender.userId),
                accessibilityTitle: name,
                size: ChatTheme.avatarSize)
        } else {
            Color.clear
                .frame(width: ChatTheme.avatarSize, height: 1)
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
            if let reply = row.reply {
                ReplyQuoteView(reply: reply, isOwn: row.isOwn)
            }
            content
            footer
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundStyle(row.isOwn ? ChatTheme.ownText : Color.primary)
        // Links stay readable on the accent-coloured own bubble.
        .tint(row.isOwn ? ChatTheme.ownText : ChatTheme.accent)
        .background(
            row.isOwn ? ChatTheme.ownBubble : ChatTheme.otherBubble,
            in: UnevenRoundedRectangle(cornerRadii: TimelineRowLayout.cornerRadii(for: row)))
    }

    @ViewBuilder
    private var content: some View {
        switch row.body {
        case .text(let text):
            TextBubble(text: text)
        case .image, .file:
            MediaBubble(body: row.body, row: row, pane: pane)
        case .placeholder(let text):
            Text(text)
                .italic()
                .foregroundStyle(row.isOwn ? ChatTheme.ownText.opacity(0.8) : Color.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: DesignTokens.spacingXS) {
            if row.isEdited {
                Text("chat.timeline.edited", tableName: "Chat")
            }
            Text(row.timeText)
            if let status = row.status {
                StatusTicks(status: status)
                if case .failed = status, MessageActionsViewModel.canRetry(row.message) {
                    Button {
                        let messageId = row.message.messageId
                        Task { await pane.retry(messageId: messageId) }
                    } label: {
                        Text("chat.timeline.action.retry", tableName: "Chat")
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .font(.caption2)
        .opacity(0.75)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var reactions: some View {
        HStack(spacing: DesignTokens.spacingXS) {
            ForEach(row.reactions, id: \.emoji) { reaction in
                Button {
                    let messageId = row.message.messageId
                    Task { await pane.toggleReaction(reaction.emoji, on: messageId) }
                } label: {
                    Text(verbatim: "\(reaction.emoji) \(reaction.count)")
                        .font(.caption)
                        .padding(.horizontal, DesignTokens.spacingS)
                        .padding(.vertical, 2)
                        .background(ChatTheme.otherBubble, in: Capsule())
                        .overlay {
                            if reaction.own {
                                Capsule().strokeBorder(ChatTheme.accent, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// The quoted message above a reply: a leading bar, the sender in bold and one line of text.
private struct ReplyQuoteView: View {
    let reply: ReplyPreview
    let isOwn: Bool

    var body: some View {
        HStack(spacing: DesignTokens.spacingS) {
            RoundedRectangle(cornerRadius: 1)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 0) {
                Text(reply.senderName)
                    .font(.caption.bold())
                Text(reply.text)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .opacity(0.85)
    }
}

/// Delivery status of an own message; the icon's accessibility label names the status.
private struct StatusTicks: View {
    let status: MessageStatus

    var body: some View {
        switch status {
        case .sending:
            Image(systemName: "clock")
                .accessibilityLabel(Text("chat.timeline.status.sending", tableName: "Chat"))
        case .sent:
            Image(systemName: "checkmark")
                .accessibilityLabel(Text("chat.timeline.status.sent", tableName: "Chat"))
        case .delivered:
            Image(systemName: "checkmark.circle")
                .accessibilityLabel(Text("chat.timeline.status.delivered", tableName: "Chat"))
        case .read:
            // The own bubble is already the accent colour, so "read" differs by the filled shape.
            Image(systemName: "checkmark.circle.fill")
                .accessibilityLabel(Text("chat.timeline.status.read", tableName: "Chat"))
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(ChatTheme.failed)
                .accessibilityLabel(Text("chat.timeline.status.failed", tableName: "Chat"))
        }
    }
}
