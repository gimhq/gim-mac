import SwiftUI

/// Detail of a section that a later step fills in.
struct SettingsPlaceholderView: View {
    let section: SettingsSection

    var body: some View {
        VStack(spacing: DesignTokens.spacingS) {
            Text(LocalizedStringKey(section.titleKey), tableName: "Settings")
                .font(.title2)
            Text("settings.section.comingSoon", tableName: "Settings")
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(Text(LocalizedStringKey(section.titleKey), tableName: "Settings"))
    }
}
