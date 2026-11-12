import GIMClientKit
import GIMFeatures
import SwiftUI

/// Settings → Account and devices: the recovery key explainer, linked devices with removal, and linking a new device.
struct AccountDevicesSection: View {
    let model: AppModel

    @State private var devices: DevicesViewModel?

    var body: some View {
        Group {
            if let devices, let client = model.client {
                AccountDevicesForm(devices: devices, client: client)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text("settings.section.accountDevices", tableName: "Settings"))
        .task {
            guard devices == nil, let client = model.client else { return }
            let devices = DevicesViewModel(client: client)
            self.devices = devices
            await devices.load()
        }
    }
}

private struct AccountDevicesForm: View {
    let devices: DevicesViewModel
    let client: any GimClientAPI

    @State private var pendingRemoval: DeviceInfo?
    @State private var showsLinkSheet = false
    @State private var recoveryKey: RecoveryKeyViewModel?

    var body: some View {
        Form {
            Section {
                Text("settings.account.recoveryKeyBody", tableName: "Settings")
                    .foregroundStyle(.secondary)
                Button {
                    showRecoveryKey()
                } label: {
                    Text("settings.account.showRecoveryKey", tableName: "Settings")
                }
            } header: {
                Text("settings.account.recoveryKeyTitle", tableName: "Settings")
            }
            Section {
                ForEach(devices.devices, id: \.deviceId) { device in
                    row(for: device)
                }
                if devices.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                if let error = devices.errorMessage {
                    HStack {
                        Text(error)
                            .foregroundStyle(.red)
                        Spacer()
                        Button {
                            Task { await devices.load() }
                        } label: {
                            Text("settings.devices.tryAgain", tableName: "Settings")
                        }
                    }
                }
                Button {
                    showsLinkSheet = true
                } label: {
                    Text("settings.devices.link", tableName: "Settings")
                }
            } header: {
                Text("settings.devices.title", tableName: "Settings")
            }
            if SettingsFeatureFlags.accountSafety {
                AccountSafetySection()
            }
        }
        .formStyle(.grouped)
        .sheet(
            isPresented: Binding(get: { recoveryKey != nil }, set: { if !$0 { recoveryKey = nil } })
        ) {
            if let recoveryKey {
                RecoveryKeySheet(viewModel: recoveryKey)
            }
        }
        .alert(
            Text("settings.devices.removeTitle", tableName: "Settings"),
            isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
            presenting: pendingRemoval
        ) { device in
            Button(role: .destructive) {
                Task { await devices.revoke(deviceId: device.deviceId) }
            } label: {
                Text("settings.devices.removeConfirm", tableName: "Settings")
            }
            Button(role: .cancel) {
            } label: {
                Text("settings.devices.cancel", tableName: "Settings")
            }
        } message: { _ in
            Text("settings.devices.removeBody", tableName: "Settings")
        }
        .sheet(isPresented: $showsLinkSheet) {
            LinkDeviceSheet(client: client) {
                Task { await devices.load() }
            }
        }
    }

    /// A new view model per opening, so the sheet always starts locked.
    private func showRecoveryKey() {
        guard let userId = client.userId() else { return }
        recoveryKey = RecoveryKeyViewModel(
            client: client, userId: userId, recoveryKit: CoreRecoveryKitFunctions(),
            authenticator: MacDeviceAuthenticator())
    }

    private func row(for device: DeviceInfo) -> some View {
        HStack(spacing: DesignTokens.spacingS) {
            Image(systemName: device.isCurrent ? "laptopcomputer" : "iphone")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
                Text(verbatim: SettingsText.deviceLabel(device))
                if device.createdAtMs > 0 {
                    let date = Date(timeIntervalSince1970: TimeInterval(device.createdAtMs) / 1000)
                        .formatted(date: .abbreviated, time: .omitted)
                    Text(String(localized: "settings.devices.added", defaultValue: "Added \(date)", table: "Settings"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if device.revoked {
                Text("settings.devices.removed", tableName: "Settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DesignTokens.spacingS)
                    .padding(.vertical, DesignTokens.spacingXS)
                    .background(.quaternary, in: Capsule())
            } else if !device.isCurrent {
                if devices.revokingDeviceId == device.deviceId {
                    ProgressView()
                        .controlSize(.small)
                }
                Button(role: .destructive) {
                    pendingRemoval = device
                } label: {
                    Text("settings.devices.remove", tableName: "Settings")
                }
                .disabled(!devices.canRevoke(device))
            }
        }
    }
}
