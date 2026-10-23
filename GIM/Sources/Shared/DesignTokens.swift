import SwiftUI

/// Spacing, sizes and colours shared by the app's views.
enum DesignTokens {
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let cornerRadius: CGFloat = 8
    static let sidebarRowHeight: CGFloat = 56
    static let avatarSidebar: CGFloat = 40
    static let avatarSmall: CGFloat = 24

    /// Avatar background colours; each one keeps white text readable. Indexed by `SidebarRowModel.colorIndex(for:)`.
    static let avatarPalette: [Color] = [
        Color(.sRGB, red: 0.00, green: 0.48, blue: 0.86),  // blue
        Color(.sRGB, red: 0.13, green: 0.59, blue: 0.33),  // green
        Color(.sRGB, red: 0.85, green: 0.47, blue: 0.02),  // orange
        Color(.sRGB, red: 0.55, green: 0.27, blue: 0.80),  // purple
        Color(.sRGB, red: 0.00, green: 0.55, blue: 0.58),  // teal
        Color(.sRGB, red: 0.80, green: 0.22, blue: 0.52),  // pink
        Color(.sRGB, red: 0.30, green: 0.35, blue: 0.80),  // indigo
    ]
}
