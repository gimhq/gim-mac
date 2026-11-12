import Foundation
import GIMClientKit
import GIMFeatures
import Observation

/// Starts direct chats (by a scanned or pasted Account ID) and groups, and opens the new chat.
@MainActor
@Observable
final class ChatStarter {
    enum Sheet: String, Identifiable {
        case newChat
        case newGroup

        var id: String { rawValue }
    }

    var sheet: Sheet?
    let newGroup: NewGroupViewModel
    /// Why the last scan, paste or scanned-id chat failed.
    var scanError: String?
    /// Account ID found by the last scan or paste.
    var scannedAccountId: String?
    private(set) var isStartingScanned = false

    private let client: any GimClientAPI
    private let openChat: @MainActor (String) -> Void

    init(client: any GimClientAPI, openChat: @escaping @MainActor (String) -> Void) {
        self.client = client
        newGroup = NewGroupViewModel(client: client)
        self.openChat = openChat
    }

    func showNewChat() {
        scanError = nil
        scannedAccountId = nil
        sheet = .newChat
    }

    func showNewGroup() {
        sheet = .newGroup
    }

    /// Starts the chat with a scanned or pasted Account ID.
    func startChat(withAccountId userId: String) async {
        guard !isStartingScanned else { return }
        isStartingScanned = true
        scanError = nil
        defer { isStartingScanned = false }
        do {
            open(try await client.createDirectChat(userId: userId))
        } catch GimError.NotFound {
            scanError = String(
                localized: "chat.new.scan.unknownAccount", defaultValue: "No account with that ID was found",
                table: "Chat")
        } catch {
            scanError = await ErrorPresenter.message(for: error, client: client)
        }
    }

    func createGroup() async {
        guard let chatId = await newGroup.create() else { return }
        open(chatId)
    }

    /// Looks for an Account ID in scanned or pasted text.
    func handleScannedText(_ text: String) {
        scannedAccountId = AccountIdToken.extract(from: text)
        scanError =
            scannedAccountId == nil
            ? String(localized: "chat.new.scan.noAccountId", defaultValue: "That text has no Account ID", table: "Chat")
            : nil
    }

    /// Reads the QR codes in a PNG, JPEG or TIFF image and takes the first Account ID among them.
    func handleImage(data: Data) async {
        scanError = nil
        scannedAccountId = nil
        let payloads = (try? await QRCodeDecoder.payloads(in: data)) ?? []
        guard !payloads.isEmpty else {
            scanError = String(
                localized: "chat.new.scan.noQrCode", defaultValue: "No QR code found in that image", table: "Chat")
            return
        }
        for payload in payloads {
            handleScannedText(payload)
            if scannedAccountId != nil { return }
        }
    }

    private func open(_ chatId: String) {
        sheet = nil
        openChat(chatId)
    }
}
