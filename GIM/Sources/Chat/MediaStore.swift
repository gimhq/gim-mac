import AppKit
import GIMClientKit
import GIMFeatures
import Observation
import UniformTypeIdentifiers

/// Thumbnails and files of a chat's attachments, fetched through the timeline once and remembered per message.
@MainActor
@Observable
final class MediaStore {
    private let timeline: TimelineViewModel
    @ObservationIgnored private var thumbnails: [String: URL] = [:]
    @ObservationIgnored private var files: [String: URL] = [:]

    /// Set when saving a file failed; merged into the pane's error.
    var errorMessage: String?

    init(timeline: TimelineViewModel) {
        self.timeline = timeline
    }

    /// Local thumbnail of the attachment; `nil` when it has none or it couldn't be fetched.
    func thumbnail(for media: MediaRef) async -> URL? {
        if let url = thumbnails[media.messageId] { return url }
        guard let path = await timeline.thumbnailPath(for: media) else { return nil }
        let url = URL(fileURLWithPath: path)
        thumbnails[media.messageId] = url
        return url
    }

    /// Local file of an image or file message, fetched on first use.
    func file(for body: MessageBody) async throws -> URL {
        guard let attachment = Self.media(of: body) else { throw MediaPreparationError.unreadable }
        let media = attachment.media
        if let url = files[media.messageId] { return url }
        let url = URL(fileURLWithPath: try await timeline.mediaFilePath(for: media, fileName: attachment.fileName))
        files[media.messageId] = url
        return url
    }

    /// Fetches the attachment, asks where to save it and copies it there.
    func saveAs(body: MessageBody, from window: NSWindow?) async {
        let source: URL
        do {
            source = try await file(for: body)
        } catch {
            errorMessage = Self.saveFailedMessage
            return
        }
        let panel = NSSavePanel()
        if case .file(_, let fileName, _, _) = body {
            panel.nameFieldStringValue = fileName
        } else {
            panel.nameFieldStringValue = Self.photoFileName(extension: source.pathExtension)
        }
        let response: NSApplication.ModalResponse
        if let window {
            response = await panel.beginSheetModal(for: window)
        } else {
            response = panel.runModal()
        }
        guard response == .OK, let destination = panel.url else { return }
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
        } catch {
            errorMessage = Self.saveFailedMessage
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    /// The attachment and the name its local file gets: the file's name, or "Photo" with the extension of the
    /// image's MIME type, so Quick Look knows the type.
    private static func media(of body: MessageBody) -> (media: MediaRef, fileName: String)? {
        switch body {
        case .image(let media, _, _, _):
            (media, photoFileName(extension: UTType(mimeType: media.mime)?.preferredFilenameExtension ?? ""))
        case .file(let media, let fileName, _, _): (media, fileName)
        case .text, .placeholder: nil
        }
    }

    /// "Photo.<extension>", "Photo.jpg" without one.
    private static func photoFileName(extension fileExtension: String) -> String {
        let name = String(localized: "chat.media.photoFileName", defaultValue: "Photo", table: "Chat")
        return "\(name).\(fileExtension.isEmpty ? "jpg" : fileExtension)"
    }

    private static var saveFailedMessage: String {
        String(localized: "chat.media.saveFailed", defaultValue: "Couldn't save the file. Try again.", table: "Chat")
    }
}
