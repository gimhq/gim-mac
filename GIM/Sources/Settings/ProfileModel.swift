import AppKit
import Foundation
import GIMClientKit
import GIMFeatures
import Observation

/// The Profile section: display name and Account ID of the signed-in user.
@MainActor
@Observable
final class ProfileModel {
    private(set) var session: Session?
    var displayNameDraft = ""
    private(set) var isBusy = false
    /// Text of the last failed action.
    private(set) var errorMessage: String?
    /// Confirmation of the last action that has no visible result, e.g. a copy.
    private(set) var infoMessage: String?

    private let client: any GimClientAPI

    init(client: any GimClientAPI) {
        self.client = client
    }

    /// The user id shown as "Account ID"; empty without a session.
    var accountId: String { session?.userId ?? "" }

    /// Whether the name field differs from the saved name.
    var isDisplayNameChanged: Bool {
        OnboardingValidation.normalizedDisplayName(displayNameDraft) != (session?.displayName ?? "")
    }

    /// Reads the session and resets the name draft to it.
    func load() async {
        do {
            session = try await client.session()
            displayNameDraft = session?.displayName ?? ""
        } catch {
            errorMessage = ErrorPresenter.message(for: error)
        }
    }

    /// Saves the trimmed name; an empty name is rejected without calling the client.
    func saveDisplayName() async {
        let name = OnboardingValidation.normalizedDisplayName(displayNameDraft)
        guard !name.isEmpty else {
            show(error: String(localized: "settings.profile.nameEmpty", table: "Settings"))
            return
        }
        await perform { try await $0.setDisplayName(name: name) }
    }

    /// Creates or opens the note to self and returns its chat id; `nil` with `errorMessage` set on failure.
    func noteToSelf() async -> String? {
        let newChat = NewChatViewModel(client: client)
        let chatId = await newChat.startNoteToSelf()
        if let error = newChat.startError { show(error: error) }
        return chatId
    }

    /// Puts the Account ID on the pasteboard.
    func copyAccountId() {
        guard !accountId.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(accountId, forType: .string)
        errorMessage = nil
        infoMessage = String(localized: "settings.profile.accountIdCopied", table: "Settings")
    }

    private func show(error: String) {
        infoMessage = nil
        errorMessage = error
    }

    /// Runs `action` while busy, then reloads the session; errors become `errorMessage`.
    private func perform(_ action: (any GimClientAPI) async throws -> Void) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        infoMessage = nil
        defer { isBusy = false }
        do {
            try await action(client)
        } catch {
            errorMessage = ErrorPresenter.message(for: error)
            return
        }
        await load()
    }
}
