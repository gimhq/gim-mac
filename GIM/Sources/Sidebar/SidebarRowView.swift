import SwiftUI

/// Avatar, title and subtitle on the left; time and unread badge on the right.
struct SidebarRowView: View {
    let row: SidebarRowModel

    var body: some View {
        HStack(spacing: DesignTokens.spacingM) {
            AvatarView(initials: row.initials, colorIndex: row.colorIndex, accessibilityTitle: row.title)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                Text(row.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: DesignTokens.spacingXS) {
                    if let sendTick = row.sendTick {
                        SendTickView(tick: sendTick)
                    }
                    Text(row.subtitle)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: DesignTokens.spacingS)
            VStack(alignment: .trailing, spacing: DesignTokens.spacingXS) {
                if let time = row.time {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let unreadText = row.unreadText {
                    Text(unreadText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignTokens.spacingS)
                        .padding(.vertical, 2)
                        .background(Color.accentColor, in: Capsule())
                }
            }
        }
        .frame(minHeight: DesignTokens.sidebarRowHeight)
        .accessibilityElement(children: .combine)
    }
}

/// Ticks of the own last message: the timeline's `StatusTicks` symbols; the label names the status.
private struct SendTickView: View {
    let tick: SidebarRowModel.SendTick

    var body: some View {
        switch tick {
        case .sending:
            Image(systemName: "clock")
                .accessibilityLabel(Text("app.sidebar.row.sendState.sending", tableName: "App"))
        case .sent:
            Image(systemName: "checkmark")
                .accessibilityLabel(Text("app.sidebar.row.sendState.sent", tableName: "App"))
        case .delivered:
            Image(systemName: "checkmark.circle")
                .accessibilityLabel(Text("app.sidebar.row.sendState.delivered", tableName: "App"))
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .accessibilityLabel(Text("app.sidebar.row.sendState.read", tableName: "App"))
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(ChatTheme.failed)
                .accessibilityLabel(Text("app.sidebar.row.sendState.failed", tableName: "App"))
        }
    }
}
