import AppKit
import SwiftUI

/// The "add member" row of the group screens: an Account ID typed or pasted as text, or read from a pasted or dropped
/// QR code image. `onAdd` runs after the field changed from an image and on Return or the Add button.
struct MemberAccountIdField: View {
    @Binding var text: String
    let isBusy: Bool
    let onAdd: () async -> Void

    var body: some View {
        HStack {
            TextField(text: $text, prompt: Text("chat.group.member.placeholder", tableName: "Chat")) {
                Text("chat.group.member.placeholder", tableName: "Chat")
            }
            .labelsHidden()
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .onSubmit { Task { await onAdd() } }
            .dropDestination(for: Data.self) { items, _ in
                guard let data = items.first else { return false }
                Task { await addFromImage(data) }
                return true
            }
            Button(action: paste) {
                Text("chat.new.scan.paste", tableName: "Chat")
            }
            .disabled(isBusy)
            Button {
                Task { await onAdd() }
            } label: {
                Text("chat.group.member.add", tableName: "Chat")
            }
            .disabled(text.isEmpty || isBusy)
        }
    }

    /// Image data first (a QR code), then text.
    private func paste() {
        let pasteboard = NSPasteboard.general
        if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            Task { await addFromImage(data) }
        } else if let string = pasteboard.string(forType: .string) {
            text = string
            Task { await onAdd() }
        }
    }

    /// Puts the QR code payloads in the field; `onAdd` takes the first valid Account ID among them.
    private func addFromImage(_ data: Data) async {
        let payloads = (try? await QRCodeDecoder.payloads(in: data)) ?? []
        guard !payloads.isEmpty else { return }
        text = payloads.joined(separator: "\n")
        await onAdd()
    }
}
