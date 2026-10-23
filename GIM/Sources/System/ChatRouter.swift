import AppKit

/// Brings the main window forward, optionally showing a chat (notifications, the menu bar).
@MainActor
final class ChatRouter {
    /// The main `WindowGroup`'s id; SwiftUI prefixes its windows' identifiers with it.
    nonisolated static let mainWindowGroupID = "main"

    private let model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    func openChat(_ chatId: String) {
        model.selectedChatId = chatId
        showMainWindow()
    }

    /// Activates the app and shows the main window; when it was closed, asks SwiftUI to open a new one.
    func showMainWindow() {
        NSApp.activate()
        let window = NSApp.windows.first {
            ($0.identifier?.rawValue ?? "").hasPrefix(Self.mainWindowGroupID) && ($0.isVisible || $0.isMiniaturized)
        }
        if let window {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
        } else {
            reopen()
        }
    }

    /// Sends the app a reopen Apple event (a Dock icon click), which SwiftUI answers by opening the main WindowGroup.
    private func reopen() {
        let target = NSAppleEventDescriptor(processIdentifier: ProcessInfo.processInfo.processIdentifier)
        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kCoreEventClass), eventID: AEEventID(kAEReopenApplication),
            targetDescriptor: target, returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID))
        _ = try? event.sendEvent(options: [.noReply], timeout: 1)
    }
}
