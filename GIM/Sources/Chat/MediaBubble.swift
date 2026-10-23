import AppKit
import GIMClientKit
import GIMFeatures
import SwiftUI

/// Photos and files in a bubble: the thumbnail, or the file's name and size, plus the caption. Double-click opens
/// Quick Look; the context menu saves the attachment or shows it in Finder. An attachment that can't be fetched
/// for now offers to try again.
struct MediaBubble: View {
    /// `body` is the view's own content, so the message body is stored under another name.
    let messageBody: MessageBody
    let row: TimelineMessageRow
    let pane: ChatPaneModel

    init(body: MessageBody, row: TimelineMessageRow, pane: ChatPaneModel) {
        messageBody = body
        self.row = row
        self.pane = pane
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingXS) {
            if row.isMediaUnavailable {
                unavailable
            } else {
                attachment
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        let messageId = row.message.messageId
                        Task { await pane.quickLook(messageId: messageId) }
                    }
                    .contextMenu { menu }
            }
            switch messageBody {
            case .image(_, _, _, let caption), .file(_, _, _, let caption):
                if let caption, !caption.isEmpty {
                    TextBubble(text: caption)
                }
            case .text, .placeholder:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var attachment: some View {
        switch messageBody {
        case .image(let media, let width, let height, _):
            ImageThumbnail(media: media, width: width, height: height, store: pane.media)
        case .file(_, let fileName, let sizeText, _):
            Label {
                VStack(alignment: .leading, spacing: 0) {
                    Text(fileName)
                        .bold()
                    Text(sizeText)
                        .font(.caption)
                        .opacity(0.8)
                }
            } icon: {
                Image(systemName: "doc")
                    .font(.title2)
                    .accessibilityLabel(Text("chat.timeline.file", tableName: "Chat"))
            }
        case .text, .placeholder:
            EmptyView()
        }
    }

    private var unavailable: some View {
        HStack(spacing: DesignTokens.spacingS) {
            Image(systemName: "exclamationmark.icloud")
                .accessibilityHidden(true)
            Text("chat.media.unavailable", tableName: "Chat")
            Button {
                pane.timeline.retryMedia(messageId: row.message.messageId)
            } label: {
                Text("chat.media.tryAgain", tableName: "Chat")
                    .underline()
            }
            .buttonStyle(.plain)
        }
        .font(.callout)
    }

    @ViewBuilder
    private var menu: some View {
        let messageId = row.message.messageId
        let attachmentBody = messageBody
        Button {
            Task { await pane.quickLook(messageId: messageId) }
        } label: {
            Text("chat.media.quickLook", tableName: "Chat")
        }
        Button {
            let window = NSApplication.shared.keyWindow
            Task { await pane.media.saveAs(body: attachmentBody, from: window) }
        } label: {
            Text("chat.media.saveAs", tableName: "Chat")
        }
        if case .file = attachmentBody {
            Button {
                let media = pane.media
                Task {
                    guard let url = try? await media.file(for: attachmentBody) else { return }
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } label: {
                Text("chat.media.showInFinder", tableName: "Chat")
            }
        }
    }
}

/// A photo's thumbnail, with a grey box of the photo's shape until it has loaded.
private struct ImageThumbnail: View {
    let media: MediaRef
    let width: UInt32?
    let height: UInt32?
    let store: MediaStore

    @State private var image: NSImage?

    private static let maxSide: CGFloat = 320

    /// The photo's size scaled down to fit 320×320, a square when the size is unknown.
    private var displaySize: CGSize {
        let size =
            image?.size
            ?? CGSize(width: CGFloat(width ?? 0), height: CGFloat(height ?? 0))
        guard size.width > 0, size.height > 0 else { return CGSize(width: Self.maxSide, height: Self.maxSide) }
        let scale = min(1, Self.maxSide / max(size.width, size.height))
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: displaySize.width, height: displaySize.height)
        .accessibilityElement()
        .accessibilityLabel(Text("chat.timeline.photo", tableName: "Chat"))
        .task(id: media.messageId) {
            guard image == nil, let url = await store.thumbnail(for: media) else { return }
            image = NSImage(contentsOf: url)
        }
    }
}
