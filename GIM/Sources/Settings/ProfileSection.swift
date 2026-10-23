import SwiftUI

/// Settings → Profile: avatar, name, username and Account ID with copy and QR code.
struct ProfileSection: View {
    let model: AppModel

    @State private var profile: ProfileModel?

    var body: some View {
        Group {
            if let profile {
                ProfileForm(profile: profile)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text("settings.section.profile", tableName: "Settings"))
        .task {
            guard profile == nil, let client = model.client else { return }
            let profile = ProfileModel(client: client)
            await profile.load()
            self.profile = profile
        }
    }
}

private struct ProfileForm: View {
    @Bindable var profile: ProfileModel

    @State private var isEditingHandle = false
    @State private var showsQRCode = false

    var body: some View {
        Form {
            Section {
                avatar
            }
            Section {
                HStack {
                    TextField(
                        String(localized: "settings.profile.name", table: "Settings"),
                        text: $profile.displayNameDraft)
                    Button {
                        Task { await profile.saveDisplayName() }
                    } label: {
                        Text("settings.profile.save", tableName: "Settings")
                    }
                    .disabled(!profile.isDisplayNameChanged || profile.isBusy)
                }
            } header: {
                Text("settings.profile.name", tableName: "Settings")
            }
            Section {
                username
            } header: {
                Text("settings.profile.username", tableName: "Settings")
            } footer: {
                Text("settings.profile.usernameHelp", tableName: "Settings")
                    .foregroundStyle(.secondary)
            }
            Section {
                accountId
            } header: {
                Text("settings.profile.accountId", tableName: "Settings")
            } footer: {
                Text("settings.profile.accountIdHelp", tableName: "Settings")
                    .foregroundStyle(.secondary)
            }
            if profile.errorMessage != nil || profile.infoMessage != nil {
                Section {
                    if let error = profile.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    if let info = profile.infoMessage {
                        Text(info)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showsQRCode) {
            MyQRCodeView(accountId: profile.accountId)
        }
    }

    private var avatar: some View {
        let name = profile.session?.displayName ?? ""
        return HStack(spacing: DesignTokens.spacingM) {
            AvatarView(
                initials: SidebarRowModel.initials(for: name),
                colorIndex: SidebarRowModel.colorIndex(for: profile.accountId),
                accessibilityTitle: name,
                size: 64)
            Text(name)
                .font(.title2)
            Spacer()
            if SettingsFeatureFlags.accountSafety {
                Button {
                } label: {
                    Text("settings.profile.changePhoto", tableName: "Settings")
                }
                .disabled(true)
            }
        }
    }

    @ViewBuilder
    private var username: some View {
        if profile.hasHandle && !isEditingHandle {
            HStack {
                Text(verbatim: "@\(profile.session?.handle ?? "")")
                Spacer()
                Button {
                    profile.handleDraft = profile.session?.handle ?? ""
                    isEditingHandle = true
                } label: {
                    Text("settings.profile.change", tableName: "Settings")
                }
                Button(role: .destructive) {
                    Task { await profile.removeHandle() }
                } label: {
                    Text("settings.profile.remove", tableName: "Settings")
                }
            }
            .disabled(profile.isBusy)
        } else {
            HStack {
                TextField(
                    String(localized: "settings.profile.username", table: "Settings"),
                    text: $profile.handleDraft)
                    .autocorrectionDisabled()
                Button {
                    Task {
                        await profile.claimHandle()
                        if profile.errorMessage == nil { isEditingHandle = false }
                    }
                } label: {
                    Text("settings.profile.claim", tableName: "Settings")
                }
                if isEditingHandle {
                    Button {
                        isEditingHandle = false
                    } label: {
                        Text("settings.profile.cancel", tableName: "Settings")
                    }
                }
            }
            .disabled(profile.isBusy)
        }
    }

    private var accountId: some View {
        HStack {
            Text(verbatim: profile.accountId)
                .font(.body.monospaced())
                .textSelection(.enabled)
            Spacer()
            Button {
                profile.copyAccountId()
            } label: {
                Text("settings.profile.copy", tableName: "Settings")
            }
            Button {
                showsQRCode = true
            } label: {
                Text("settings.profile.myQRCode", tableName: "Settings")
            }
        }
    }
}
