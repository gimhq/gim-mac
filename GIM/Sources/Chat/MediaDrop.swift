import AppKit
import GIMFeatures
import UniformTypeIdentifiers

/// Files and images dropped on a chat pane or pasted into the composer, sent one by one through the composer.
enum MediaDrop {
    static let acceptedTypes: [UTType] = [.fileURL, .image, .png, .jpeg, .tiff]

    /// The file URLs of the providers that carry one.
    static func fileURLs(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            let url = await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    continuation.resume(returning: url)
                }
            }
            if let url { urls.append(url) }
        }
        return urls
    }

    /// The image data of the providers without a file URL, such as an image dragged out of a browser.
    static func imageData(from providers: [NSItemProvider]) async -> [Data] {
        var result: [Data] = []
        for provider in providers where !provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            let type = provider.registeredTypeIdentifiers.lazy
                .compactMap { UTType($0) }
                .first { $0.conforms(to: .image) }
            guard let type else { continue }
            let data = await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
                _ = provider.loadDataRepresentation(for: type) { data, _ in
                    continuation.resume(returning: data)
                }
            }
            if let data { result.append(data) }
        }
        return result
    }

    /// Whether the file can be sent, else why not.
    static func isSendable(_ url: URL) -> (ok: Bool, reason: MediaPreparationError?) {
        do {
            try MediaPreparation.validateSize(try MediaPreparation.fileSize(atPath: url.path))
            return (true, nil)
        } catch let error as MediaPreparationError {
            return (false, error)
        } catch {
            return (false, .unreadable)
        }
    }

    /// Sends each file, then each image through a temporary file that is deleted afterwards. Failures show in the
    /// composer's error.
    @MainActor
    static func send(urls: [URL], imageData: [Data], through composer: ComposerViewModel) async {
        for url in urls {
            let check = isSendable(url)
            guard check.ok else {
                composer.attachmentFailed(check.reason ?? MediaPreparationError.unreadable)
                continue
            }
            _ = await composer.sendAttachment(atPath: url.path)
        }
        for data in imageData {
            guard let image = NSImage(data: data), let export = ImageExport.data(from: image) else {
                composer.attachmentFailed(MediaPreparationError.unreadable)
                continue
            }
            do {
                let file = try ImageExport.writeTemporaryFile(export.data, fileExtension: export.fileExtension)
                defer { try? FileManager.default.removeItem(at: file) }
                _ = await composer.sendAttachment(atPath: file.path)
            } catch {
                composer.attachmentFailed(error)
            }
        }
    }
}
