import AppKit
import Observation
import UserNotifications

/// Local notifications for new messages: permission, posting, and opening the chat when one is clicked.
@MainActor
@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    /// `.notDetermined` until `refreshStatus()` has read the settings.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    /// Called with the chat id of a clicked notification.
    @ObservationIgnored var onOpenChat: ((String) -> Void)?

    @ObservationIgnored private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    /// Reads the current permission into `authorizationStatus`.
    func refreshStatus() {
        center.getNotificationSettings { @Sendable settings in
            let status = settings.authorizationStatus
            Task { @MainActor in self.authorizationStatus = status }
        }
    }

    /// Asks for permission the first time only (the system remembers the answer), then refreshes the status.
    func requestAuthorizationIfNeeded(preferences: SystemPreferences) {
        guard !preferences.notificationsRequested else {
            refreshStatus()
            return
        }
        preferences.notificationsRequested = true
        center.requestAuthorization(options: [.alert, .sound, .badge]) { @Sendable _, _ in
            Task { @MainActor in self.refreshStatus() }
        }
    }

    func post(_ content: LocalNotificationContent, sound: Bool) {
        let notification = UNMutableNotificationContent()
        notification.title = content.title
        notification.body = content.body
        notification.threadIdentifier = content.threadIdentifier
        notification.sound = sound ? .default : nil
        notification.userInfo = ["chatId": content.chatId]
        let request = UNNotificationRequest(
            identifier: "\(content.chatId)-\(UUID())", content: notification, trigger: nil)
        center.add(request, withCompletionHandler: nil)
    }

    /// Opens the app's page in System Settings > Notifications, where the system switch lives.
    static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let chatId = response.notification.request.content.userInfo["chatId"] as? String
        Task { @MainActor in
            if let chatId { self.onOpenChat?(chatId) }
        }
        completionHandler()
    }

    /// Shown while the app is frontmost too: `NotificationPolicy` already skipped the chat on screen.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
