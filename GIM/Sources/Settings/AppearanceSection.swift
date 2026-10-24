import SwiftUI

/// Settings → Appearance: light or dark, open at login, menu bar mode and the Dock icon.
struct AppearanceSection: View {
    let system: SystemServices

    var body: some View {
        let preferences = system.preferences
        let launchAtLogin = system.launchAtLogin
        Form {
            Section {
                Picker(
                    selection: Binding(get: { preferences.appearance }, set: { system.setAppearance($0) })
                ) {
                    ForEach(AppearanceChoice.allCases, id: \.self) { choice in
                        Text(choice.titleKey, tableName: "Settings")
                            .tag(choice)
                    }
                } label: {
                    Text("settings.section.appearance", tableName: "Settings")
                }
                .pickerStyle(.radioGroup)
            }
            Section {
                Toggle(
                    isOn: Binding(get: { launchAtLogin.isEnabled }, set: { launchAtLogin.setEnabled($0) })
                ) {
                    Text("settings.launchAtLogin.toggle", tableName: "Settings")
                }
                if launchAtLogin.requiresApproval {
                    HStack {
                        Text("settings.launchAtLogin.requiresApproval", tableName: "Settings")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            LaunchAtLoginController.openLoginItemsSettings()
                        } label: {
                            Text("settings.launchAtLogin.openSettings", tableName: "Settings")
                        }
                    }
                }
                if let error = launchAtLogin.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            Section {
                Toggle(
                    isOn: Binding(get: { preferences.menuBarMode }, set: { system.setMenuBarMode($0) })
                ) {
                    Text("settings.menuBar.toggle", tableName: "Settings")
                }
                Toggle(
                    isOn: Binding(get: { preferences.hideDockIcon }, set: { system.setHideDockIcon($0) })
                ) {
                    Text("settings.menuBar.hideDockIcon", tableName: "Settings")
                    Text("settings.menuBar.hideDockIconHelp", tableName: "Settings")
                }
                .disabled(!preferences.menuBarMode)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("settings.section.appearance", tableName: "Settings"))
        .onAppear { launchAtLogin.refresh() }
    }
}
