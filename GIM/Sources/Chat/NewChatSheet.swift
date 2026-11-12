import AppKit
import GIMClientKit
import GIMFeatures
import SwiftUI
import UniformTypeIdentifiers

/// Reads an Account ID from a pasted or dropped QR code or text, and starts the chat.
struct NewChatSheet: View {
    let starter: ChatStarter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingM) {
            Text("chat.new.title", tableName: "Chat")
                .font(.title2.bold())
            scanSection
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("chat.new.cancel", tableName: "Chat")
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 240)
    }

    private var scanSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingS) {
            Text("chat.new.scan.title", tableName: "Chat")
                .font(.headline)
            HStack {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("chat.new.scan.hint", tableName: "Chat")
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: paste) {
                    Text("chat.new.scan.paste", tableName: "Chat")
                }
            }
            .padding(DesignTokens.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                    .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
            .contentShape(Rectangle())
            .focusable()
            .dropDestination(for: Data.self) { items, _ in
                guard let data = items.first else { return false }
                Task { await starter.handleImage(data: data) }
                return true
            }
            .onPasteCommand(of: [.image, .png, .tiff, .plainText]) { _ in paste() }
            if let accountId = starter.scannedAccountId {
                HStack {
                    Text(
                        String(
                            localized: "chat.new.scan.found",
                            defaultValue: "Account ID \(UserLabel.shortUserId(accountId))", table: "Chat"))
                    Spacer()
                    Button {
                        Task { await starter.startChat(withAccountId: accountId) }
                    } label: {
                        Text("chat.new.start", tableName: "Chat")
                    }
                    .disabled(starter.isStartingScanned)
                }
            }
            if let scanError = starter.scanError {
                errorText(scanError)
            }
        }
    }

    /// Image data first, then text.
    private func paste() {
        let pasteboard = NSPasteboard.general
        if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            Task { await starter.handleImage(data: data) }
        } else if let text = pasteboard.string(forType: .string) {
            starter.handleScannedText(text)
        }
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.red)
    }
}
