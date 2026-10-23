import GIMClientKit
import GIMFeatures
import SwiftUI

/// Adds a server by its address; closes once the server was added.
struct AddServerSheet: View {
    @State private var addHub: AddHubViewModel
    @Environment(\.dismiss) private var dismiss

    init(client: any GimClientAPI) {
        _addHub = State(initialValue: AddHubViewModel(client: client))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            Text("settings.addServer.title", tableName: "Settings")
                .font(.title2)
            Text("settings.addServer.body", tableName: "Settings")
                .fixedSize(horizontal: false, vertical: true)
            TextField(
                String(localized: "settings.addServer.placeholder", table: "Settings"),
                text: Bindable(addHub).url)
                .autocorrectionDisabled()
                .onSubmit { Task { await addHub.submit() } }
            if let urlError = addHub.urlError {
                Text(urlError)
                    .foregroundStyle(.secondary)
            }
            if let error = addHub.errorMessage {
                if let key = SettingsText.addServerErrorKey(error) {
                    Text(LocalizedStringKey(key), tableName: "Settings")
                        .foregroundStyle(.red)
                } else {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            HStack {
                Spacer()
                if addHub.isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                }
                Button {
                    dismiss()
                } label: {
                    Text("settings.addServer.cancel", tableName: "Settings")
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    Task { await addHub.submit() }
                } label: {
                    Text("settings.addServer.add", tableName: "Settings")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!addHub.canSubmit)
            }
        }
        .padding(DesignTokens.spacingL)
        .frame(width: 420)
        .onChange(of: addHub.addedHub) { _, added in
            if added != nil { dismiss() }
        }
    }
}
