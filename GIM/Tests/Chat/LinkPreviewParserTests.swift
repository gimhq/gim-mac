import XCTest

@testable import GIM

final class LinkPreviewParserTests: XCTestCase {
    private let base = URL(string: "https://example.com/articles/one")!

    func testParsesOpenGraphTags() {
        let html = """
            <html><head>
            <title>Fallback title</title>
            <meta property="og:title" content="Boats of the Aegean">
            <meta property="og:description" content="A short   guide
              to sailing.">
            <meta property="og:image" content="/images/boat.jpg">
            <meta property="og:site_name" content="Sea News">
            </head><body><meta property="og:title" content="Body tag"></body></html>
            """
        let preview = LinkPreviewParser.parse(html: html, baseURL: base)
        XCTAssertEqual(preview.title, "Boats of the Aegean")
        XCTAssertEqual(preview.description, "A short guide to sailing.")
        XCTAssertEqual(preview.imageURL, URL(string: "https://example.com/images/boat.jpg"))
        XCTAssertEqual(preview.siteName, "Sea News")
        XCTAssertEqual(preview.url, base)
        XCTAssertFalse(preview.isEmpty)
    }

    func testFallsBackToTitleAndMetaDescription() {
        let html = """
            <HEAD><TITLE>Plain page</TITLE>
            <meta content='Only the basics.' NAME='description'>
            </HEAD>
            """
        let preview = LinkPreviewParser.parse(html: html, baseURL: base)
        XCTAssertEqual(preview.title, "Plain page")
        XCTAssertEqual(preview.description, "Only the basics.")
        XCTAssertNil(preview.imageURL)
        XCTAssertNil(preview.siteName)
    }

    func testDecodesEntities() {
        let html = """
            <head><meta name="twitter:title" content="Fish &amp; chips &#39;n&#x27; more &lt;3"></head>
            """
        let preview = LinkPreviewParser.parse(html: html, baseURL: base)
        XCTAssertEqual(preview.title, "Fish & chips 'n' more <3")
    }

    func testDropsNonWebImage() {
        let html = """
            <head><title>T</title><meta property="og:image" content="javascript:alert(1)"></head>
            """
        XCTAssertNil(LinkPreviewParser.parse(html: html, baseURL: base).imageURL)
    }

    func testCapsTitleLength() {
        let long = String(repeating: "a", count: 300)
        let preview = LinkPreviewParser.parse(html: "<title>\(long)</title>", baseURL: base)
        XCTAssertEqual(preview.title?.count, 200)
    }

    func testEmptyPageIsEmpty() {
        XCTAssertTrue(LinkPreviewParser.parse(html: "<html></html>", baseURL: base).isEmpty)
    }

    func testFirstURL() {
        XCTAssertEqual(
            LinkDetector.firstURL(in: "see https://example.com/a and http://b.test"),
            URL(string: "https://example.com/a"))
        XCTAssertNil(LinkDetector.firstURL(in: "mail me at a@b.test"))
        XCTAssertEqual(
            LinkDetector.firstURL(in: "https://example.com/path."), URL(string: "https://example.com/path"))
    }
}
