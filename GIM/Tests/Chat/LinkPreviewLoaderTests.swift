import Foundation
import Synchronization
import XCTest

@testable import GIM

/// Serves canned responses by URL and counts the requests it sees.
private final class StubURLProtocol: URLProtocol {
    struct Response {
        var status: Int
        var contentType: String
        var body: Data
    }

    private static let state = Mutex<(responses: [URL: Response], counts: [URL: Int])>(([:], [:]))

    static func serve(_ url: URL, status: Int = 200, contentType: String, body: String) {
        state.withLock { $0.responses[url] = Response(status: status, contentType: contentType, body: Data(body.utf8)) }
    }

    static func requestCount(for url: URL) -> Int {
        state.withLock { $0.counts[url] ?? 0 }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        let response = Self.state.withLock { state -> Response? in
            state.counts[url, default: 0] += 1
            return state.responses[url]
        }
        guard let response,
            let http = HTTPURLResponse(
                url: url, statusCode: response.status, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": response.contentType])
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class LinkPreviewLoaderTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-link-loader-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    /// A URL no other test uses, so request counts stay separate.
    private func uniqueURL(_ path: String) -> URL {
        URL(string: "https://\(UUID().uuidString.lowercased()).test/\(path)")!
    }

    private func makeLoader(maxHTMLBytes: Int = LinkPreviewParser.maxHTMLBytes) -> (LinkPreviewLoader, LinkPreviewCache) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let cache = LinkPreviewCache(directory: directory)
        let loader = LinkPreviewLoader(
            session: URLSession(configuration: configuration), cache: cache, maxHTMLBytes: maxHTMLBytes)
        return (loader, cache)
    }

    func testLoadsAndCachesHTMLPreview() async {
        let url = uniqueURL("page")
        StubURLProtocol.serve(
            url, contentType: "text/html; charset=utf-8",
            body: """
                <head><meta property="og:title" content="Harbour"><meta property="og:description" content="Boats.">
                <meta property="og:image" content="/boat.png"></head>
                """)
        let (loader, cache) = makeLoader()

        let first = await loader.preview(for: url)
        XCTAssertEqual(first?.title, "Harbour")
        XCTAssertEqual(first?.description, "Boats.")
        XCTAssertEqual(first?.imageURL, url.deletingLastPathComponent().appendingPathComponent("boat.png"))
        let cached = await cache.preview(for: url)
        XCTAssertEqual(cached, first)

        let second = await loader.preview(for: url)
        XCTAssertEqual(second, first)
        XCTAssertEqual(StubURLProtocol.requestCount(for: url), 1)
    }

    func testNotFoundIsNotRetried() async {
        let url = uniqueURL("missing")
        StubURLProtocol.serve(url, status: 404, contentType: "text/html", body: "<title>Not found</title>")
        let (loader, _) = makeLoader()

        let first = await loader.preview(for: url)
        let second = await loader.preview(for: url)
        XCTAssertNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(StubURLProtocol.requestCount(for: url), 1)
    }

    func testNonHTMLIsRejected() async {
        let url = uniqueURL("data.json")
        StubURLProtocol.serve(url, contentType: "application/json", body: "{\"title\": \"No\"}")
        let (loader, _) = makeLoader()

        let preview = await loader.preview(for: url)
        XCTAssertNil(preview)
    }

    func testLargeBodyIsCutButKeepsEarlyTitle() async {
        let url = uniqueURL("big")
        let filler = String(repeating: "<p>filler</p>", count: 2000)
        StubURLProtocol.serve(url, contentType: "text/html", body: "<title>Early title</title>\(filler)</head>")
        let (loader, _) = makeLoader(maxHTMLBytes: 4096)

        let preview = await loader.preview(for: url)
        XCTAssertEqual(preview?.title, "Early title")
    }

    func testNonWebURLIsNeverRequested() async {
        let url = URL(string: "ftp://example.com/file")!
        let (loader, _) = makeLoader()

        let preview = await loader.preview(for: url)
        XCTAssertNil(preview)
        XCTAssertEqual(StubURLProtocol.requestCount(for: url), 0)
    }
}
