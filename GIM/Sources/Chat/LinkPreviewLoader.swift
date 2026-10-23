import Foundation

/// Fetches previews straight from the linked page (never through the server), backed by `LinkPreviewCache`.
final class LinkPreviewLoader: Sendable {
    static let shared: LinkPreviewLoader = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        configuration.httpAdditionalHeaders = ["Accept": "text/html", "User-Agent": "gim-mac"]
        configuration.httpShouldSetCookies = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let directory =
            LinkPreviewCache.defaultDirectory()
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("link-previews", isDirectory: true)
        return LinkPreviewLoader(
            session: URLSession(configuration: configuration), cache: LinkPreviewCache(directory: directory))
    }()

    private let session: URLSession
    private let cache: LinkPreviewCache
    private let maxHTMLBytes: Int
    private let previewsInFlight = InFlight<LinkPreview?>()
    private let imagesInFlight = InFlight<Data?>()

    init(session: URLSession, cache: LinkPreviewCache, maxHTMLBytes: Int = LinkPreviewParser.maxHTMLBytes) {
        self.session = session
        self.cache = cache
        self.maxHTMLBytes = maxHTMLBytes
    }

    /// The preview of `url`, or nil when the page has none or can't be fetched.
    func preview(for url: URL) async -> LinkPreview? {
        guard LinkDetector.isWeb(url) else { return nil }
        return await previewsInFlight.run(url) { await self.loadPreview(url) }
    }

    /// The preview's image bytes, or nil when there is no image or it can't be fetched.
    func image(for preview: LinkPreview) async -> Data? {
        guard let url = preview.imageURL, LinkDetector.isWeb(url) else { return nil }
        return await imagesInFlight.run(url) { await self.loadImage(url) }
    }

    private func loadPreview(_ url: URL) async -> LinkPreview? {
        if let cached = await cache.preview(for: url) {
            return cached
        }
        if await cache.hasRecentFailure(for: url) {
            return nil
        }
        let html: String
        switch await fetch(url, contentType: { $0.contains("text/html") }, limit: maxHTMLBytes, truncate: true) {
        case .body(let data):
            html = Self.decode(data)
        case .rejected:
            await cache.storeFailure(for: url)
            return nil
        case .unreachable:
            // Offline or timed out: try again next time instead of marking the link dead.
            return nil
        }
        let preview = LinkPreviewParser.parse(html: html, baseURL: url)
        guard !preview.isEmpty else {
            await cache.storeFailure(for: url)
            return nil
        }
        await cache.store(preview)
        return preview
    }

    private func loadImage(_ url: URL) async -> Data? {
        if let cached = await cache.image(for: url) {
            return cached
        }
        guard
            case .body(let data) = await fetch(
                url, contentType: { $0.hasPrefix("image/") }, limit: cache.maxImageBytes, truncate: false)
        else { return nil }
        await cache.storeImage(data, for: url)
        return data
    }

    private enum FetchResult {
        case body(Data)
        /// The page answered, but not with something usable.
        case rejected
        case unreachable
    }

    /// GETs `url` and reads at most `limit` bytes; a longer body is cut (`truncate`) or rejected.
    private func fetch(
        _ url: URL, contentType accepts: (String) -> Bool, limit: Int, truncate: Bool
    ) async -> FetchResult {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        do {
            let (bytes, response) = try await session.bytes(for: request, delegate: RedirectGuard())
            defer { bytes.task.cancel() }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                let type = http.value(forHTTPHeaderField: "Content-Type")?.lowercased(), accepts(type)
            else { return .rejected }
            var data = Data()
            for try await byte in bytes {
                guard data.count < limit else {
                    return truncate ? .body(data) : .rejected
                }
                data.append(byte)
            }
            return .body(data)
        } catch {
            return .unreachable
        }
    }

    /// UTF-8, allowing a character cut in half at the end; ISO Latin 1 otherwise.
    private static func decode(_ data: Data) -> String {
        for cut in 0...3 where data.count >= cut {
            if let text = String(data: data.dropLast(cut), encoding: .utf8) {
                return text
            }
        }
        return String(data: data, encoding: .isoLatin1) ?? ""
    }
}

/// Refuses redirects that leave http(s).
private final class RedirectGuard: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(
        _ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard let url = request.url, LinkDetector.isWeb(url) else { return nil }
        return request
    }
}

/// One running task per URL; later callers wait for the same result.
private actor InFlight<Value: Sendable> {
    private var tasks: [URL: Task<Value, Never>] = [:]

    func run(_ url: URL, _ work: @escaping @Sendable () async -> Value) async -> Value {
        if let task = tasks[url] {
            return await task.value
        }
        let task = Task { await work() }
        tasks[url] = task
        let value = await task.value
        tasks[url] = nil
        return value
    }
}
