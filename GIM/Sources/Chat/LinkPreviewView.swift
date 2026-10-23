import AppKit
import SwiftUI

/// A card for the linked page: image, site, title and description. Shows nothing until a preview loads.
struct LinkPreviewView: View {
    let url: URL
    let loader: LinkPreviewLoader
    @State private var preview: LinkPreview?
    @State private var image: NSImage?

    init(url: URL, loader: LinkPreviewLoader = .shared) {
        self.url = url
        self.loader = loader
    }

    var body: some View {
        Group {
            if let preview {
                Button {
                    NSWorkspace.shared.open(preview.url)
                } label: {
                    card(preview)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityTitle(preview))
            }
        }
        .task(id: url) {
            preview = nil
            image = nil
            guard let loaded = await loader.preview(for: url) else { return }
            preview = loaded
            if let data = await loader.image(for: loaded) {
                image = NSImage(data: data)
            }
        }
    }

    private func card(_ preview: LinkPreview) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image {
                Color.clear
                    .frame(height: 160)
                    .overlay {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
            VStack(alignment: .leading, spacing: 2) {
                if let site = preview.siteName ?? preview.url.host() {
                    Text(verbatim: site)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let title = preview.title {
                    Text(verbatim: title)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                }
                if let description = preview.description {
                    Text(verbatim: description)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(DesignTokens.spacingS)
        }
        .frame(maxWidth: ChatTheme.maxBubbleWidth, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                .strokeBorder(.tertiary, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius))
    }

    private func accessibilityTitle(_ preview: LinkPreview) -> String {
        let title = preview.title ?? preview.url.host() ?? preview.url.absoluteString
        return String(localized: "chat.preview.open", defaultValue: "Open link \(title)", table: "Chat")
    }
}
