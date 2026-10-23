/// Decides whether a new message gets a notification.
enum NotificationPolicy {
    /// No notification for the chat the person is looking at: the app is frontmost and the main window shows it.
    /// Chats open in their own window still notify (follow-up).
    static func shouldNotify(appIsActive: Bool, selectedChatId: String?, chatId: String) -> Bool {
        !appIsActive || selectedChatId != chatId
    }
}
