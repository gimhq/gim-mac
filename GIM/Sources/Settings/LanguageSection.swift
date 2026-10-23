import SwiftUI

/// Settings → Language: the app's language, and a restart to show it.
struct LanguageSection: View {
    @State private var language = LanguageModel()
    /// "Later" hides the restart row until the language changes again.
    @State private var postponed = false

    var body: some View {
        Form {
            Section {
                Picker(
                    selection: Binding(
                        get: { language.choice },
                        set: {
                            language.select($0)
                            postponed = false
                        })
                ) {
                    ForEach(LanguageChoice.allCases, id: \.self) { choice in
                        Text(choice.titleKey, tableName: "Settings")
                            .tag(choice)
                    }
                } label: {
                    Text("settings.section.language", tableName: "Settings")
                }
                .pickerStyle(.radioGroup)
            }
            if language.needsRelaunch && !postponed {
                Section {
                    HStack(spacing: DesignTokens.spacingS) {
                        Text("settings.language.restartNeeded", tableName: "Settings")
                        Spacer()
                        Button {
                            postponed = true
                        } label: {
                            Text("settings.language.later", tableName: "Settings")
                        }
                        Button {
                            AppRelauncher.relaunch()
                        } label: {
                            Text("settings.language.restart", tableName: "Settings")
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("settings.section.language", tableName: "Settings"))
    }
}
