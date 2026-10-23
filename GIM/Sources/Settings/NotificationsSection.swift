import AppKit
import SwiftUI
import UserNotifications

/// Settings → Notifications: whether macOS lets gim notify, plus sound and Dock badge.
struct NotificationsSection: View {
    let system: SystemServices

    var body: some View {
        @Bindable var preferences = system.preferences
        Form {
            Section {
                status
                Button {
                    NotificationService.openSystemSettings()
                } label: {
                    Text("settings.notifications.openSystemSettings", tableName: "Settings")
                }
            }
            Section {
                Toggle(isOn: $preferences.notificationSounds) {
                    Text("settings.notifications.sound", tableName: "Settings")
                }
                Toggle(isOn: $preferences.showsBadge) {
                    Text("settings.notifications.badge", tableName: "Settings")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("settings.section.notifications", tableName: "Settings"))
        .onAppear { system.notifications.refreshStatus() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            system.notifications.refreshStatus()
        }
    }

    @ViewBuilder
    private var status: some View {
        switch system.notifications.authorizationStatus {
        case .authorized, .provisional:
            Text("settings.notifications.on", tableName: "Settings")
        case .denied:
            Text("settings.notifications.off", tableName: "Settings")
        case .notDetermined:
            HStack {
                Text("settings.notifications.notAsked", tableName: "Settings")
                Spacer()
                Button {
                    system.notifications.requestAuthorizationIfNeeded(preferences: system.preferences)
                } label: {
                    Text("settings.notifications.allow", tableName: "Settings")
                }
            }
        @unknown default:
            Text("settings.notifications.off", tableName: "Settings")
        }
    }
}
