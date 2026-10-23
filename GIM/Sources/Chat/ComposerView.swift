import AppKit
import SwiftUI

/// The bar under the message list: the reply or edit bar, then the attachment button, the input and the send button.
/// A chat that can no longer be written to shows why instead.
struct ComposerView: View {
    let pane: ChatPaneModel

    var body: some View {
        let composer = pane.composer
        VStack(spacing: 0) {
            if let readOnlyText = composer.readOnlyText {
                Text(readOnlyText)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: ChatTheme.bottomBarHeight)
            } else {
                if composer.editTarget != nil {
                    EditBar { composer.cancelEdit() }
                } else if let replyTarget = composer.replyTarget {
                    ReplyBar(preview: replyTarget) { composer.setReplyTarget(nil) }
                }
                inputRow
            }
        }
        .task(id: ObjectIdentifier(pane)) {
            pane.focusComposer()
        }
        .onDisappear {
            pane.composer.disappear()
        }
    }

    private var inputRow: some View {
        let composer = pane.composer
        return HStack(alignment: .bottom, spacing: DesignTokens.spacingS) {
            Button(action: chooseAttachment) {
                Image(systemName: "paperclip")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(!composer.canAttach)
            .help(Text("chat.composer.attach", tableName: "Chat"))
            .accessibilityLabel(Text("chat.composer.attach", tableName: "Chat"))
            .padding(.bottom, DesignTokens.spacingXS + 2)

            ComposerTextView(
                text: Binding(get: { pane.composer.text }, set: { pane.composer.textChanged($0) }),
                placeholder: String(localized: "chat.composer.placeholder", defaultValue: "Write a message", table: "Chat"),
                isEnabled: !composer.isReadOnly,
                focusRequest: pane.composerFocusRequest,
                onSend: send,
                onEditLastMessage: { pane.editLastOwnMessage() },
                onPasteImage: { _ in })
            .id(ObjectIdentifier(pane))
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                    .fill(Color(nsColor: .textBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                    .strokeBorder(Color(nsColor: .separatorColor)))

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .foregroundStyle(composer.canSend ? AnyShapeStyle(ChatTheme.accent) : AnyShapeStyle(.secondary))
            .disabled(!composer.canSend)
            .help(Text("chat.composer.send", tableName: "Chat"))
            .accessibilityLabel(Text("chat.composer.send", tableName: "Chat"))
            .padding(.bottom, DesignTokens.spacingXS)
        }
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.spacingS)
    }

    private func send() {
        Task { await pane.send() }
    }

    /// Lets the user pick one file and sends it through the composer.
    private func chooseAttachment() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let composer = pane.composer
        Task { await composer.sendAttachment(atPath: url.path) }
    }
}
