import AppKit

/// The unread count on the Dock icon.
enum DockBadge {
    /// `nil` (no badge) for no unread messages or when the badge is off; counts above 999 show "999+".
    static func label(count: Int, enabled: Bool) -> String? {
        guard enabled, count > 0 else { return nil }
        return count > 999 ? "999+" : "\(count)"
    }

    @MainActor
    static func apply(count: Int, enabled: Bool) {
        NSApp.dockTile.badgeLabel = label(count: count, enabled: enabled)
    }
}
