import GIMClientKit
import GIMFeatures
import SwiftUI

/// Settings → Advanced: the user's servers, with making one the main server, removing one and adding one.
struct ServersSection: View {
    let model: AppModel

    @State private var hubs: HubsViewModel?

    var body: some View {
        Group {
            if let hubs, let client = model.client {
                ServersForm(hubs: hubs, client: client)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text("settings.section.advanced", tableName: "Settings"))
        .onAppear {
            if hubs == nil, let client = model.client {
                hubs = HubsViewModel(client: client)
            }
            hubs?.start()
        }
        .onDisappear {
            hubs?.stop()
        }
    }
}

private struct ServersForm: View {
    let hubs: HubsViewModel
    let client: any GimClientAPI

    @State private var showsAddSheet = false

    var body: some View {
        Form {
            Section {
                if hubs.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                ForEach(hubs.hubs, id: \.hubId) { hub in
                    row(for: hub)
                }
                if let error = hubs.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
                Button {
                    showsAddSheet = true
                } label: {
                    Text("settings.servers.add", tableName: "Settings")
                }
            } header: {
                Text("settings.servers.title", tableName: "Settings")
            } footer: {
                Text("settings.servers.help", tableName: "Settings")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .alert(
            Text("settings.servers.removeTitle", tableName: "Settings"),
            isPresented: Binding(
                get: { hubs.pendingRemoval != nil }, set: { if !$0 { hubs.cancelRemoval() } }),
            presenting: hubs.pendingRemoval
        ) { hub in
            Button(role: .destructive) {
                Task { await hubs.confirmRemoval(of: hub) }
            } label: {
                Text("settings.servers.removeConfirm", tableName: "Settings")
            }
            Button(role: .cancel) {
            } label: {
                Text("settings.servers.cancel", tableName: "Settings")
            }
        } message: { _ in
            Text("settings.servers.removeBody", tableName: "Settings")
        }
        .alert(
            Text("settings.servers.ownedGroupsTitle", tableName: "Settings"),
            isPresented: Binding(
                get: { hubs.ownedGroupsWarning != nil }, set: { if !$0 { hubs.cancelOwnedGroupsRemoval() } }),
            presenting: hubs.ownedGroupsWarning
        ) { warning in
            Button(role: .destructive) {
                Task { await hubs.confirmOwnedGroupsRemoval(warning) }
            } label: {
                Text("settings.servers.removeAnyway", tableName: "Settings")
            }
            Button(role: .cancel) {
            } label: {
                Text("settings.servers.cancel", tableName: "Settings")
            }
        } message: { warning in
            Text(warning.message)
        }
        .alert(
            Text(verbatim: hubs.notice?.title ?? ""),
            isPresented: Binding(get: { hubs.notice != nil }, set: { if !$0 { hubs.dismissNotice() } }),
            presenting: hubs.notice
        ) { _ in
            Button {
            } label: {
                Text("settings.servers.ok", tableName: "Settings")
            }
        } message: { notice in
            Text(notice.message)
        }
        .sheet(isPresented: $showsAddSheet) {
            AddServerSheet(client: client)
        }
    }

    private func row(for hub: HubInfo) -> some View {
        HStack(spacing: DesignTokens.spacingS) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                HStack(spacing: DesignTokens.spacingS) {
                    Text(verbatim: HubsViewModel.address(of: hub))
                    if hub.isPrimary {
                        Text("settings.servers.main", tableName: "Settings")
                            .font(.caption)
                            .padding(.horizontal, DesignTokens.spacingS)
                            .padding(.vertical, DesignTokens.spacingXS)
                            .background(.tint.opacity(0.15), in: Capsule())
                    }
                }
                Text(verbatim: HubsViewModel.stateText(hub.state))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if hubs.busyHubId == hub.hubId {
                ProgressView()
                    .controlSize(.small)
            }
            if hub.state != .removed {
                if !hub.isPrimary {
                    Button {
                        Task { await hubs.setPrimary(hubId: hub.hubId) }
                    } label: {
                        Text("settings.servers.makeMain", tableName: "Settings")
                    }
                    .disabled(!hubs.canSetPrimary(hub))
                }
                Button(role: .destructive) {
                    hubs.requestRemoval(hub)
                } label: {
                    Text("settings.servers.remove", tableName: "Settings")
                }
                .disabled(!hubs.canRemove(hub))
            }
        }
    }
}
