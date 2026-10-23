import SwiftUI

/// Contract C7: the account-safety entries, shown only when `SettingsFeatureFlags.accountSafety` is on. Every entry is
/// disabled and does nothing yet.
struct AccountSafetySection: View {
    var body: some View {
        Section {
            entry("settings.safety.privacy", systemImage: "hand.raised")
            entry("settings.safety.blockedUsers", systemImage: "person.crop.circle.badge.xmark")
            entry("settings.safety.newRecoveryKey", systemImage: "key")
            entry("settings.safety.deleteAccount", systemImage: "trash")
        } header: {
            Text("settings.safety.title", tableName: "Settings")
        }
    }

    private func entry(_ key: String, systemImage: String) -> some View {
        Label {
            Text(LocalizedStringKey(key), tableName: "Settings")
        } icon: {
            Image(systemName: systemImage)
        }
        .disabled(true)
        .foregroundStyle(.secondary)
    }
}
