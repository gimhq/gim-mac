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
                Text(row.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
