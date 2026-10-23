import SwiftUI

/// A round avatar with initials on a colour from `DesignTokens.avatarPalette`. Group avatar images come later.
struct AvatarView: View {
    let initials: String
    let colorIndex: Int
    /// Read by VoiceOver instead of the initials.
    let accessibilityTitle: String
    var size: CGFloat = DesignTokens.avatarSidebar

    var body: some View {
        ZStack {
            Circle()
                .fill(Self.color(at: colorIndex))
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
    }

    private static func color(at index: Int) -> Color {
        let palette = DesignTokens.avatarPalette
        let wrapped = ((index % palette.count) + palette.count) % palette.count
        return palette[wrapped]
    }
}
