import GIMFeatures
import SwiftUI

/// Photos and files in a bubble. For now a placeholder: an icon with "Photo" or the file name and size, plus the
/// caption.
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
            switch messageBody {
            case .image(_, _, _, let caption):
                Label {
                    Text("chat.timeline.photo", tableName: "Chat")
                } icon: {
                    Image(systemName: "photo")
                }
                captionView(caption)
            case .file(_, let fileName, let sizeText, let caption):
                Label {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(fileName)
                        Text(sizeText)
                            .font(.caption)
                            .opacity(0.8)
                    }
                } icon: {
                    Image(systemName: "doc")
                        .accessibilityLabel(Text("chat.timeline.file", tableName: "Chat"))
                }
                captionView(caption)
            case .text, .placeholder:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func captionView(_ caption: String?) -> some View {
        if let caption, !caption.isEmpty {
            TextBubble(text: caption)
        }
    }
}
