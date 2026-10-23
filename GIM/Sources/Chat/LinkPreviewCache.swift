import CryptoKit
import Foundation

/// Previews and their images in memory and on disk, one `<sha256>.json` (and `<sha256>.img`) per URL.
/// Every error is a cache miss; nothing is thrown to callers.
actor LinkPreviewCache {
    /// How long a failed fetch keeps a link from being tried again.
    static let failureLifetime: TimeInterval = 60 * 60

    let directory: URL
    let maxEntries: Int
    let maxImageBytes: Int
    private var memory: [String: LinkPreview] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL, maxEntries: Int = 500, maxImageBytes: Int = 2 * 1024 * 1024) {
        self.directory = directory
        self.maxEntries = maxEntries
        self.maxImageBytes = maxImageBytes
    }

    /// `<app data>/link-previews`, or nil when the data directory can't be reached.
    static func defaultDirectory() -> URL? {
        try? AppDirectories.dataDirectory.appendingPathComponent("link-previews", isDirectory: true)
    }

    /// The stored preview, or nil on a miss or for a failed fetch.
    func preview(for url: URL) -> LinkPreview? {
        guard let entry = entry(for: url), !entry.isEmpty else { return nil }
        return entry
    }

    /// True while a failed fetch of `url` is younger than `failureLifetime`.
    func hasRecentFailure(for url: URL) -> Bool {
        guard let entry = entry(for: url), entry.isEmpty else { return false }
        return Date().timeIntervalSince(entry.fetchedAt) < Self.failureLifetime
    }

    func store(_ preview: LinkPreview) {
        let key = Self.key(for: preview.url)
        if memory.count >= maxEntries {
            memory.removeAll()
        }
        memory[key] = preview
        guard ensureDirectory(), let data = try? encoder.encode(preview) else { return }
        try? data.write(to: fileURL(key, "json"), options: .atomic)
        prune()
    }

    /// Remembers that `url` gave no preview, so it is not fetched again for an hour.
    func storeFailure(for url: URL) {
        store(LinkPreview(url: url, title: nil, description: nil, imageURL: nil, siteName: nil, fetchedAt: Date()))
    }

    func image(for url: URL) -> Data? {
        try? Data(contentsOf: fileURL(Self.key(for: url), "img"))
    }

    /// Keeps `data` unless it is larger than `maxImageBytes`.
    func storeImage(_ data: Data, for url: URL) {
        guard data.count <= maxImageBytes, ensureDirectory() else { return }
        try? data.write(to: fileURL(Self.key(for: url), "img"), options: .atomic)
    }

    /// Removes the oldest entries (by modification date) beyond `maxEntries`, with their images.
    func prune() {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey]
        guard
            let files = try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: Array(keys))
        else { return }
        let entries = files.filter { $0.pathExtension == "json" }
        guard entries.count > maxEntries else { return }
        let dated = entries.map { file in
            (file, (try? file.resourceValues(forKeys: keys).contentModificationDate) ?? .distantPast)
        }
        for (file, _) in dated.sorted(by: { $0.1 < $1.1 }).prefix(entries.count - maxEntries) {
            let key = file.deletingPathExtension().lastPathComponent
            memory[key] = nil
            try? FileManager.default.removeItem(at: file)
            try? FileManager.default.removeItem(at: fileURL(key, "img"))
        }
    }

    private func entry(for url: URL) -> LinkPreview? {
        let key = Self.key(for: url)
        if let cached = memory[key] {
            return cached
        }
        guard let data = try? Data(contentsOf: fileURL(key, "json")),
            let preview = try? decoder.decode(LinkPreview.self, from: data)
        else { return nil }
        memory[key] = preview
        return preview
    }

    private func ensureDirectory() -> Bool {
        (try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)) != nil
    }

    private func fileURL(_ key: String, _ fileExtension: String) -> URL {
        directory.appendingPathComponent("\(key).\(fileExtension)", isDirectory: false)
    }

    private static func key(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
