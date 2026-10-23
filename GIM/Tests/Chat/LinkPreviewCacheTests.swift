import XCTest

@testable import GIM

final class LinkPreviewCacheTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-link-previews-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    private func makePreview(_ path: String) -> LinkPreview {
        LinkPreview(
            url: URL(string: "https://example.com/\(path)")!, title: "Title \(path)", description: "About \(path)",
            imageURL: URL(string: "https://example.com/\(path).png"), siteName: "Example",
            fetchedAt: Date(timeIntervalSince1970: 1_800_000_000))
    }

    private func files(withExtension fileExtension: String) -> [URL] {
        let all = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return all.filter { $0.pathExtension == fileExtension }
    }

    func testStoredPreviewIsReadFromDisk() async {
        let preview = makePreview("a")
        await LinkPreviewCache(directory: directory).store(preview)
        let fresh = LinkPreviewCache(directory: directory)
        let loaded = await fresh.preview(for: preview.url)
        XCTAssertEqual(loaded, preview)
    }

    func testMissReturnsNil() async {
        let loaded = await LinkPreviewCache(directory: directory).preview(for: URL(string: "https://example.com/x")!)
        XCTAssertNil(loaded)
    }

    func testStoreImageRespectsLimit() async {
        let cache = LinkPreviewCache(directory: directory, maxImageBytes: 8)
        let big = URL(string: "https://example.com/big.png")!
        let small = URL(string: "https://example.com/small.png")!
        await cache.storeImage(Data(repeating: 1, count: 9), for: big)
        await cache.storeImage(Data(repeating: 2, count: 8), for: small)
        let bigData = await cache.image(for: big)
        let smallData = await cache.image(for: small)
        XCTAssertNil(bigData)
        XCTAssertEqual(smallData, Data(repeating: 2, count: 8))
    }

    func testFailureIsNotAPreviewButIsStored() async {
        let cache = LinkPreviewCache(directory: directory)
        let url = URL(string: "https://example.com/dead")!
        await cache.storeFailure(for: url)
        let loaded = await cache.preview(for: url)
        let failed = await cache.hasRecentFailure(for: url)
        XCTAssertNil(loaded)
        XCTAssertTrue(failed)
        XCTAssertEqual(files(withExtension: "json").count, 1)
    }

    func testOldFailureExpires() async {
        let cache = LinkPreviewCache(directory: directory)
        let url = URL(string: "https://example.com/old")!
        await cache.store(
            LinkPreview(
                url: url, title: nil, description: nil, imageURL: nil, siteName: nil,
                fetchedAt: Date().addingTimeInterval(-2 * LinkPreviewCache.failureLifetime)))
        let failed = await cache.hasRecentFailure(for: url)
        XCTAssertFalse(failed)
    }

    func testPruneKeepsMaxEntries() async {
        let cache = LinkPreviewCache(directory: directory, maxEntries: 2)
        for path in ["a", "b", "c"] {
            await cache.store(makePreview(path))
        }
        await cache.prune()
        XCTAssertEqual(files(withExtension: "json").count, 2)
    }
}
