import SwiftUI

/// Settings → Help and about: how gim works, the version and the licences. Works offline.
struct HelpAboutSection: View {
    @State private var showsExplainer = false

    private let versionInfo = AppVersionInfo.current

    var body: some View {
        let version = versionInfo.version
        let build = versionInfo.build
        Form {
            Section {
                Button {
                    showsExplainer = true
                } label: {
                    Text("settings.about.howItWorks", tableName: "Settings")
                }
            }
            Section {
                Text(
                    String(
                        localized: "settings.about.version", defaultValue: "Version \(version) (\(build))",
                        table: "Settings"))
                    .textSelection(.enabled)
                // GIMKit has no version of its own yet; it ships with the app.
                Text(String(localized: "settings.about.gimkit", defaultValue: "GIMKit \(version)", table: "Settings"))
                    .textSelection(.enabled)
                DisclosureGroup {
                    Text("settings.about.licences", tableName: "Settings")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("settings.about.licencesTitle", tableName: "Settings")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("settings.section.helpAbout", tableName: "Settings"))
        .sheet(isPresented: $showsExplainer) {
            VStack(spacing: 0) {
                ExplainerView()
                Divider()
                HStack {
                    Spacer()
                    Button {
                        showsExplainer = false
                    } label: {
                        Text("settings.about.done", tableName: "Settings")
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(DesignTokens.spacingM)
            }
            .frame(width: 480, height: 600)
        }
    }
}
