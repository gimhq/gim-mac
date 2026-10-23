import AppKit
import GIMClientKit
import Observation

/// The app's ties to macOS: notifications for new messages, the Dock badge, launch at login, menu bar mode and the
/// appearance. Made once next to `AppModel` and started when the main window appears.
@MainActor
@Observable
final class SystemServices {
    let model: AppModel
    let preferences: SystemPreferences
    let notifications: NotificationService
    let unread: UnreadTracker
    let launchAtLogin: LaunchAtLoginController
    let router: ChatRouter

    @ObservationIgnored private var isStarted = false
    @ObservationIgnored private var trackedClient: (any GimClientAPI)?

    init(
        model: AppModel, preferences: SystemPreferences = SystemPreferences(),
        notifications: NotificationService = NotificationService()
    ) {
        self.model = model
        self.preferences = preferences
        self.notifications = notifications
        unread = UnreadTracker()
        launchAtLogin = LaunchAtLoginController()
        router = ChatRouter(model: model)
    }

    /// Applies the saved preferences and starts following the signed-in client. Safe to call again.
    func start() {
        guard !isStarted else { return }
        isStarted = true
        AppearanceChoice.apply(preferences.appearance)
        DockIconPolicy.apply(hidden: preferences.menuBarMode && preferences.hideDockIcon)
        model.showsMenuBarExtra = preferences.menuBarMode
        notifications.onOpenChat = { [router] in router.openChat($0) }
        unread.onNewMessage = { [weak self] in self?.handle($0) }
        launchAtLogin.refresh()
        notifications.refreshStatus()
        observeClient()
        observeBadge()
    }

    func setAppearance(_ choice: AppearanceChoice) {
        preferences.appearance = choice
        AppearanceChoice.apply(choice)
    }

    /// Turning menu bar mode off always brings the Dock icon back.
    func setMenuBarMode(_ enabled: Bool) {
        preferences.menuBarMode = enabled
        model.showsMenuBarExtra = enabled
        DockIconPolicy.apply(hidden: enabled && preferences.hideDockIcon)
    }

    /// Takes effect while menu bar mode is on.
    func setHideDockIcon(_ hidden: Bool) {
        preferences.hideDockIcon = hidden
        DockIconPolicy.apply(hidden: preferences.menuBarMode && hidden)
    }

    private func handle(_ event: NewMessageEvent) {
        guard
            NotificationPolicy.shouldNotify(
                appIsActive: NSApp.isActive, selectedChatId: model.selectedChatId, chatId: event.chatId)
        else { return }
        notifications.post(NotificationContentMapper.content(for: event), sound: preferences.notificationSounds)
    }

    /// Follows the client while signed in (`.ready`): the client exists during onboarding too, but has no chat list
    /// until an identity exists. The first sign-in asks for notification permission.
    private func observeClient() {
        let client = withObservationTracking {
            model.phase == .ready ? model.client : nil
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeClient() }
        }
        guard client !== trackedClient else { return }
        trackedClient = client
        if let client {
            unread.attach(client)
            notifications.requestAuthorizationIfNeeded(preferences: preferences)
        } else {
            // Clearing the tracker clears the badge through `observeBadge()`.
            unread.detach()
        }
    }

    private func observeBadge() {
        let (count, enabled) = withObservationTracking {
            (unread.totalUnread, preferences.showsBadge)
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeBadge() }
        }
        DockBadge.apply(count: count, enabled: enabled)
    }
}
