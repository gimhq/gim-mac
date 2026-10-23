import AppKit
import GIMClientKit
import GIMFeatures
import SwiftUI

/// What a key press in the composer does.
enum ComposerKeyRule {
    enum Action: Equatable {
        case send
        case newline
        case editLastMessage
        case passThrough
    }

    static let returnKeyCode: UInt16 = 36
    static let keypadEnterKeyCode: UInt16 = 76
    static let upArrowKeyCode: UInt16 = 126

    /// Return and keypad Enter send, with Shift or Option they insert a newline; Up arrow in an empty composer edits
    /// the last own message. Everything else, including Command and Control combinations, goes to the text view.
    static func action(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, isTextEmpty: Bool) -> Action {
        let flags = modifiers.intersection([.shift, .option, .command, .control])
        switch keyCode {
        case returnKeyCode, keypadEnterKeyCode:
            if flags.isEmpty { return .send }
            if flags == .shift || flags == .option { return .newline }
            return .passThrough
        case upArrowKeyCode:
            return flags.isEmpty && isTextEmpty ? .editLastMessage : .passThrough
        default:
            return .passThrough
        }
    }
}

/// "Replying to <sender>" and a one-line preview of the message, with a cancel button.
struct ReplyBar: View {
    let preview: MessageItem
    let onCancel: () -> Void

    var body: some View {
        let sender = UserLabel.name(for: preview.sender)
        ComposerBar(onCancel: onCancel) {
            Text(String(localized: "chat.composer.replyingTo", defaultValue: "Replying to \(sender)", table: "Chat"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(ChatTheme.accent)
            Text(ComposerViewModel.previewText(for: preview))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

/// "Editing message" with a cancel button.
struct EditBar: View {
    let onCancel: () -> Void

    var body: some View {
        ComposerBar(onCancel: onCancel) {
            Text("chat.composer.editing", tableName: "Chat")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ChatTheme.accent)
        }
    }
}

/// A bar above the composer input: a leading accent line, the content and a cancel button.
private struct ComposerBar<Content: View>: View {
    let onCancel: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: DesignTokens.spacingS) {
            RoundedRectangle(cornerRadius: 1)
                .fill(ChatTheme.accent)
                .frame(width: 2)
            VStack(alignment: .leading, spacing: 2) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(Text("chat.composer.cancel", tableName: "Chat"))
            .accessibilityLabel(Text("chat.composer.cancel", tableName: "Chat"))
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.top, DesignTokens.spacingS)
    }
}
