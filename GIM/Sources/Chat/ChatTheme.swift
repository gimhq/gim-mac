import AppKit
import SwiftUI

/// Colours and sizes used only by the chat pane; spacing comes from `DesignTokens`.
enum ChatTheme {
    static let ownBubble = Color(nsColor: .controlAccentColor)
    static let otherBubble = Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
    static let ownText = Color.white
    static let selectionBackground = Color(nsColor: .selectedContentBackgroundColor).opacity(0.15)
    static let failed = Color(nsColor: .systemRed)
    static let accent = Color(nsColor: .controlAccentColor)
    static let maxBubbleWidth: CGFloat = 480
    static let avatarSize: CGFloat = DesignTokens.avatarSmall
    static let bubbleRadius: CGFloat = 16
    /// Corner on the tail side of the last bubble of a run.
    static let tailRadius: CGFloat = 4
    static let headerAvatarSize: CGFloat = 32
    static let bottomBarHeight: CGFloat = 44
    static let paneMinWidth: CGFloat = 360
}
