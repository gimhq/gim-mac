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

    let client: any GimClientAPI
    let chatId: String
    let ownUserId: String?
    let timeline: TimelineViewModel
    let actions: MessageActionsViewModel
    let composer: ComposerViewModel
    let media: MediaStore
    let quickLook = QuickLookController()
    let search = ChatSearch()

    /// Set by the view from the app's activity.
    var isAppActive = true
    /// Whether the newest row is on screen; set by the timeline list.
    var isBottomVisible = false
    /// The row highlighted by a click.
    var selectedMessageId: String?
    /// Incremented to move the keyboard focus into the composer.
    var composerFocusRequest = 0
    /// Whether the chat info popover is open.
    var showsGroupInfo = false
    /// Incremented to move the keyboard focus into the search field.
    var searchFocusRequest = 0

    init(
        client: any GimClientAPI, chatId: String, ownUserId: String?,
        mediaDirectory: String? = (try? AppDirectories.dataDirectory)?.appendingPathComponent("media").path
    ) {
        self.client = client
        self.chatId = chatId
        self.ownUserId = ownUserId
        let timeline = TimelineViewModel(
            client: client, chatId: chatId, mediaDirectory: mediaDirectory, pageSize: 50)
        self.timeline = timeline
        actions = MessageActionsViewModel(client: client, chatId: chatId)
        composer = ComposerViewModel(client: client, chatId: chatId, drafts: Self.drafts, timeline: timeline)
        media = MediaStore(timeline: timeline)
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
        timeline.errorMessage ?? actions.errorMessage ?? composer.errorMessage ?? media.errorMessage
    }

    func dismissError() {
        timeline.dismissError()
        actions.dismissError()
        composer.dismissError()
        media.dismissError()
    }

    var isGroup: Bool {
        timeline.isGroup
    }

    func markReadIfNeeded() async {
        await timeline.markReadIfNeeded(bottomVisible: isBottomVisible, appActive: isAppActive)
    }

    // MARK: - Composer

    func focusComposer() {
        composerFocusRequest += 1
    }

    /// Sends the composer's text or edit, then puts the focus back into the composer.
    func send() async {
        await composer.send()
        focusComposer()
    }

    /// Starts editing the newest own text message.
    func editLastOwnMessage() {
        let message = timeline.items.reversed().lazy
            .compactMap { $0.messageRow?.message }
            .first { ComposerViewModel.canEdit($0) }
        guard let message else { return }
        composer.beginEdit(message)
    }

    /// Replies to the selected message.
    func replyToSelected() {
        guard let selectedMessageId else { return }
        reply(to: selectedMessageId)
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

    // MARK: - Search

    func showSearch() {
        search.activate()
        searchFocusRequest += 1
    }

    /// Recomputes the matches over the loaded timeline; called when the query or the timeline changes.
    func updateSearch() {
        search.update(items: timeline.items)
    }

    func findNext() {
        search.next()
    }

    func findPrevious() {
        search.previous()
    }

    func closeSearch() {
        search.close()
    }

    // MARK: - Media

    /// Whether the selected message is a photo or a file.
    var selectedMessageIsMedia: Bool {
        selectedMessageId.flatMap(mediaBody(of:)) != nil
    }

    /// Opens the message's attachment in Quick Look; does nothing for other messages.
    func quickLook(messageId: String?) async {
        guard let messageId, let body = mediaBody(of: messageId) else { return }
        guard let url = try? await media.file(for: body) else { return }
        quickLook.preview(url: url)
    }

    func quickLookSelected() async {
        await quickLook(messageId: selectedMessageId)
    }

    func saveSelectedAs() async {
        guard let selectedMessageId, let body = mediaBody(of: selectedMessageId) else { return }
        await media.saveAs(body: body, from: NSApplication.shared.keyWindow)
    }

    /// Sends dropped or pasted files and images.
    func sendDropped(urls: [URL], imageData: [Data]) async {
        await MediaDrop.send(urls: urls, imageData: imageData, through: composer)
    }

    private func mediaBody(of messageId: String) -> MessageBody? {
        let row = timeline.items.first { $0.id == TimelineDisplayItem.id(forMessage: messageId) }?.messageRow
        switch row?.body {
        case .image, .file: return row?.body
        default: return nil
        }
    }
}
