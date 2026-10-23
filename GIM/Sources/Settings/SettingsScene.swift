import SwiftUI

/// The Settings window: a section list with Sign out under it and the selected section's detail.
///
/// Signed out (onboarding or launching) the detail only asks the user to sign in.
struct SettingsScene: View {
    let model: AppModel
    let system: SystemServices

    @State private var selection: SettingsSection? = .profile

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label {
                    Text(LocalizedStringKey(section.titleKey), tableName: "Settings")
                } icon: {
                    Image(systemName: section.systemImage)
                }
                .tag(section)
            }
            .safeAreaInset(edge: .bottom) {
                SignOutButton(model: model)
                    .padding(DesignTokens.spacingM)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            if model.client == nil || model.phase != .ready {
                Text("settings.signedOut.body", tableName: "Settings")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                detail(for: selection ?? .profile)
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .navigationTitle(Text("settings.window.title", tableName: "Settings"))
    }

    /// One line per section so each section's view replaces exactly one line.
    @ViewBuilder
    private func detail(for section: SettingsSection) -> some View {
        switch section {
        case .profile: ProfileSection(model: model)
        case .accountDevices: AccountDevicesSection(model: model)
        case .notifications: NotificationsSection(system: system)
        case .appearance: AppearanceSection(system: system)
        case .language: LanguageSection()
        case .advanced: ServersSection(model: model)
        case .helpAbout: HelpAboutSection()
        }
    }
}
