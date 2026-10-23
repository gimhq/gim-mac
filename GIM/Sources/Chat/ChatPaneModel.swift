import AppKit
import GIMClientKit
import GIMFeatures
import Observation

/// One open chat pane: the timeline, the message actions and the composer of one chat.
@MainActor
@Observable
final class ChatPaneModel {
    /// Unsent text per chat, shared by every pane of the process.
    static let drafts = ComposerDrafts()

    let chatId: String
    let ownUserId: String?
    let timeline: TimelineViewModel
    let actions: MessageActionsViewModel
    let composer: ComposerViewModel

    /// Set by the view from the app's activity.
    var isAppActive = true
    /// Whether the newest row is on screen; set by the timeline list.
    var isBottomVisible = false
    /// The row highlighted by a click.
    var selectedMessageId: String?

    init(client: any GimClientAPI, chatId: String, ownUserId: String?, mediaDirectory: String? = nil) {
        self.chatId = chatId
        self.ownUserId = ownUserId
        let timeline = TimelineViewModel(
            client: client, chatId: chatId, mediaDirectory: mediaDirectory, pageSize: 50)
        self.timeline = timeline
        actions = MessageActionsViewModel(client: client, chatId: chatId)
        composer = ComposerViewModel(client: client, chatId: chatId, drafts: Self.drafts, timeline: timeline)
    }

    func start() {
        timeline.start()
    }

    func stop() {
        timeline.stop()
    }

    /// The chat name, else the shortened chat id until the chat list arrives.
    var title: String {
        timeline.title.isEmpty ? UserLabel.shortUserId(chatId) : timeline.title
    }

    /// Who is typing, if anyone.
    var subtitle: String? {
        timeline.typingText
    }

    var errorMessage: String? {
        timeline.errorMessage ?? actions.errorMessage ?? composer.errorMessage
    }

    func dismissError() {
        timeline.dismissError()
        actions.dismissError()
        composer.dismissError()
    }

    func markReadIfNeeded() async {
        await timeline.markReadIfNeeded(bottomVisible: isBottomVisible, appActive: isAppActive)
    }

    // MARK: - Message actions

    func reply(to messageId: String) {
        guard let message = timeline.message(withId: messageId) else { return }
        composer.setReplyTarget(message)
    }

    func edit(messageId: String) {
        guard let message = timeline.message(withId: messageId), ComposerViewModel.canEdit(message) else { return }
        composer.beginEdit(message)
    }

    func copy(messageId: String) {
        guard let message = timeline.message(withId: messageId),
            let text = MessageActionsViewModel.copyText(for: message)
        else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func toggleReaction(_ emoji: String, on messageId: String) async {
        guard let message = timeline.message(withId: messageId) else { return }
        await actions.toggleReaction(emoji, on: message)
    }

    func requestDelete(messageId: String) {
        guard let message = timeline.message(withId: messageId) else { return }
        actions.requestDelete(message)
    }

    /// Deletes the message waiting for confirmation. Takes it right away, before the alert's dismissal cancels it.
    func confirmDelete() {
        guard let message = actions.pendingDelete else { return }
        Task { await actions.delete(message) }
    }

    func cancelDelete() {
        actions.cancelDelete()
    }

    func retry(messageId: String) async {
        await timeline.retry(messageId: messageId)
    }
}
