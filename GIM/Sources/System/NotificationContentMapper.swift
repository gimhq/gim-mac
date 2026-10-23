import Foundation
import GIMClientKit

/// What a local notification for a new message shows.
struct LocalNotificationContent: Equatable, Sendable {
    var title: String
    var body: String
    /// Groups the notifications of a chat; the chat id.
    var threadIdentifier: String
    var chatId: String
}

/// Maps a new message to notification content, like `NotificationPresentation` does for pushes.
enum NotificationContentMapper {
    /// The title is the chat title, or "<sender> in <chat>" in a group when the sender's name differs from the chat
    /// title; without a chat title it is the sender's name. The body is the text gim-core rendered ("Photo", …).
    static func content(for event: NewMessageEvent) -> LocalNotificationContent {
        let sender = event.senderName
        let chat = event.chatTitle
        let title: String
        if chat.isEmpty {
            title = sender
        } else if event.kind == .group, !sender.isEmpty, sender != chat {
            title = String(
                localized: "settings.notification.senderInChat", defaultValue: "\(sender) in \(chat)",
                table: "Settings")
        } else {
            title = chat
        }
        return LocalNotificationContent(
            title: title, body: event.text, threadIdentifier: event.chatId, chatId: event.chatId)
    }
}
