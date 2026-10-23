import GIMFeatures
import SwiftUI

/// Layout rules of message rows: spacing, avatars, sender names, alignment and bubble corners.
struct TimelineRowLayout {
    /// Gap between two rows of a run.
    static let runSpacing: CGFloat = 2
    /// Gap after the last row of a run.
    static let tailSpacing: CGFloat = 12

    static func spacingAfter(row: TimelineMessageRow) -> CGFloat {
        row.hasTail ? tailSpacing : runSpacing
    }

    /// Groups only, not for own messages, on the first row of a run.
    static func showsAvatar(row: TimelineMessageRow, isGroup: Bool) -> Bool {
        isGroup && !row.isOwn && row.isFirstInRun
    }

    static func showsSenderName(row: TimelineMessageRow) -> Bool {
        row.senderName != nil
    }

    static func alignment(for row: TimelineMessageRow) -> HorizontalAlignment {
        row.isOwn ? .trailing : .leading
    }

    /// The run-end bubble gets a smaller corner at the bottom of its tail side.
    static func cornerRadii(for row: TimelineMessageRow) -> RectangleCornerRadii {
        let large = ChatTheme.bubbleRadius
        let tail = row.hasTail ? ChatTheme.tailRadius : large
        return RectangleCornerRadii(
            topLeading: large,
            bottomLeading: row.isOwn ? large : tail,
            bottomTrailing: row.isOwn ? tail : large,
            topTrailing: large)
    }
}
