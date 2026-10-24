import SwiftUI

/// The menu bar extra's icon, with the unread count next to it when there is one.
struct MenuBarExtraLabel: View {
    let system: SystemServices

    var body: some View {
        let count = system.unread.totalUnread
        HStack(spacing: DesignTokens.spacingXS) {
            Image(systemName: "bubble.left.and.bubble.right")
            if count > 0 {
                Text(count, format: .number)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                String(
                    localized: "settings.menuBar.accessibility", defaultValue: "gim, \(count) unread",
                    table: "Settings")))
    }
}
