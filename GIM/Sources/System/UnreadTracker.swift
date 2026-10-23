import Foundation
import GIMClientKit
import GIMFeatures
import Observation

/// A message from someone else that arrived while the app was running.
struct NewMessageEvent: Equatable, Sendable {
    var chatId: String
    var chatTitle: String
    var kind: ChatKind
    var senderName: String
    var text: String
    var sentAtMs: UInt64
}

/// The chat list as gim-core delivers it plus the newest message time seen per chat; turns diff batches into
/// new-message events. Pure, so it is tested without a client.
struct UnreadLedger {
    private(set) var chats: [ChatSummary] = []
    /// A batch did not fit the list; the list must be subscribed again (its first batch is a reset).
    private(set) var isOutOfSync = false
    private var lastSentAtMs: [String: UInt64] = [:]
    private var isSeeded = false

    /// Unread messages over the chats this device is still a member of.
    var totalUnread: Int {
        chats.filter { $0.state == .active }.reduce(0) { $0 + Int($1.unreadCount) }
    }

    /// Applies one batch and returns an event per chat whose last message is someone else's and newer than the one
    /// seen before (or the chat is new). The first batch (the subscription's reset) only seeds. A batch that does not
    /// fit is dropped and sets `isOutOfSync`; the next batch seeds again.
    mutating func apply(_ diffs: [ChatListDiff]) -> [NewMessageEvent] {
        var updated = chats
        do {
            try DiffApplier.apply(diffs, to: &updated)
        } catch {
            isOutOfSync = true
            isSeeded = false
            return []
        }
        chats = updated
        isOutOfSync = false
        var events: [NewMessageEvent] = []
        for chat in chats {
            guard let message = chat.lastMessage else { continue }
            let seen = lastSentAtMs[chat.chatId]
            if isSeeded, !message.isOwn, seen.map({ message.sentAtMs > $0 }) ?? true {
                events.append(
                    NewMessageEvent(
                        chatId: chat.chatId, chatTitle: chat.name, kind: chat.kind, senderName: message.senderName,
                        text: message.text, sentAtMs: message.sentAtMs))
            }
            lastSentAtMs[chat.chatId] = max(seen ?? 0, message.sentAtMs)
        }
        isSeeded = true
        return events
    }
}

/// Follows the chat list of the signed-in client for the unread total, the menu bar chat list and new-message
/// events (notifications).
@MainActor
@Observable
final class UnreadTracker {
    /// In list order as delivered.
    private(set) var chats: [ChatSummary] = []
    private(set) var totalUnread = 0
    @ObservationIgnored var onNewMessage: ((NewMessageEvent) -> Void)?

    @ObservationIgnored private var ledger = UnreadLedger()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var client: (any GimClientAPI)?

    /// Starts following `client`'s chat list; replaces a previous client.
    func attach(_ client: any GimClientAPI) {
        detach()
        self.client = client
        subscribe(client)
    }

    /// Stops following and clears the state.
    func detach() {
        task?.cancel()
        task = nil
        client = nil
        ledger = UnreadLedger()
        chats = []
        totalUnread = 0
    }

    private func subscribe(_ client: any GimClientAPI) {
        task = Task { [weak self] in
            guard let stream = try? await ListenerBridge.chatList(client) else { return }
            for await diffs in stream {
                guard let self, !Task.isCancelled else { return }
                self.receive(diffs, from: client)
            }
        }
    }

    private func receive(_ diffs: [ChatListDiff], from client: any GimClientAPI) {
        let events = ledger.apply(diffs)
        if ledger.isOutOfSync {
            // A new subscription starts with a reset.
            task?.cancel()
            subscribe(client)
            return
        }
        chats = ledger.chats
        totalUnread = ledger.totalUnread
        for event in events {
            onNewMessage?(event)
        }
    }
}
