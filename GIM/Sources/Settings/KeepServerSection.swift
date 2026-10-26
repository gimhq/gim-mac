import GIMFeatures
import SwiftUI

/// Settings → Advanced: the Keep server, on or off, its address and going back to the default one. The choice applies
/// to the client created next, so a change asks to restart.
struct KeepServerSection: View {
    let model: AppModel

    @State private var keep: KeepServerViewModel?

    var body: some View {
        Section {
            if let keep {
                KeepServerRows(keep: keep)
            }
        } header: {
            Text("settings.keep.title", tableName: "Settings")
        } footer: {
            Text("settings.keep.footer", tableName: "Settings")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            if keep == nil {
                keep = model.makeKeepServerViewModel()
            }
        }
    }
}

private struct KeepServerRows: View {
    @Bindable var keep: KeepServerViewModel

    var body: some View {
        Toggle(isOn: Binding(get: { keep.isOn }, set: { keep.setOn($0) })) {
            Text("settings.keep.toggle", tableName: "Settings")
        }
        if keep.isOn {
            HStack(spacing: DesignTokens.spacingS) {
                TextField(text: $keep.draft, prompt: Text(verbatim: "https://")) {
                    Text("settings.keep.address", tableName: "Settings")
                }
                .autocorrectionDisabled()
                .onSubmit { keep.save() }
                Button {
                    keep.save()
                } label: {
                    Text("settings.keep.save", tableName: "Settings")
                }
                .disabled(keep.draft == keep.url)
            }
            if let error = keep.errorKind {
                Text(error.text)
                    .foregroundStyle(.red)
            }
            HStack(spacing: DesignTokens.spacingS) {
                if !keep.isDefault, let defaultUrl = keep.defaultUrl {
                    Text(
                        String(
                            localized: "settings.keep.default", defaultValue: "Default: \(defaultUrl)",
                            table: "Settings")
                    )
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    keep.resetToDefault()
                } label: {
                    Text("settings.keep.useDefault", tableName: "Settings")
                }
                .disabled(keep.isDefault)
            }
        }
        if keep.needsRestart {
            HStack(spacing: DesignTokens.spacingS) {
                Text("settings.keep.restartNeeded", tableName: "Settings")
                Spacer()
                Button {
                    AppRelauncher.relaunch()
                } label: {
                    Text("settings.keep.restart", tableName: "Settings")
                }
            }
        }
    }
}
