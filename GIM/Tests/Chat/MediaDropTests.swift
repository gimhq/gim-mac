import AppKit
import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

/// `MediaDrop`: the size check and sending dropped files and pasted images through the composer.
@MainActor
final class MediaDropTests: XCTestCase {
    private func temporaryFile(_ fileExtension: String) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-tests-drop-\(UUID().uuidString)").appendingPathExtension(fileExtension)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    /// PNG data of a small opaque image.
    private func pngData() throws -> Data {
        let rep = try XCTUnwrap(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: 8, pixelsHigh: 4, bitsPerSample: 8, samplesPerPixel: 3,
                hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        return try XCTUnwrap(rep.representation(using: .png, properties: [:]))
    }

    /// A started pane on the demo direct chat, once its messages arrived.
    private func makePane() async throws -> ChatPaneModel {
        let model = makeTestModel()
        await model.start()
        try await model.createDemoIdentity(displayName: "Alex")
        let client = try XCTUnwrap(model.client)
        let mediaDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-mac-tests-media-\(UUID().uuidString)", isDirectory: true).path
        let pane = ChatPaneModel(
            client: client, chatId: "chat-sofia", ownUserId: model.session?.userId, mediaDirectory: mediaDirectory)
        pane.start()
        await waitUntil { pane.timeline.items.contains { $0.messageRow != nil } }
        return pane
    }

    private static func imageCount(_ pane: ChatPaneModel) -> Int {
        pane.timeline.items.filter {
            if case .image = $0.messageRow?.body { true } else { false }
        }.count
    }

    private static func lastMessageIsOwnImage(_ pane: ChatPaneModel) -> Bool {
        guard let row = pane.timeline.items.last(where: { $0.messageRow != nil })?.messageRow,
            case .image = row.body
        else { return false }
        return row.message.isOwn
    }

    /// Yields, then sleeps briefly, until `condition` holds or about two seconds passed.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<200 {
            if condition() { return }
            await Task.yield()
        }
        for _ in 0..<100 {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private func outgoingFiles() -> [String] {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("gim-outgoing").path
        return (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
    }

    func testSmallFileIsSendable() throws {
        let url = temporaryFile("txt")
        try Data("crew".utf8).write(to: url)
        let check = MediaDrop.isSendable(url)
        XCTAssertTrue(check.ok)
        XCTAssertNil(check.reason)
    }

    func testFileOverLimitIsTooLarge() throws {
        let url = temporaryFile("zip")
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: nil))
        let handle = try FileHandle(forWritingTo: url)
        try handle.truncate(atOffset: MediaPreparation.maxFileSize + 1)
        try handle.close()
        let check = MediaDrop.isSendable(url)
        XCTAssertFalse(check.ok)
        XCTAssertEqual(check.reason, .tooLarge(byteCount: MediaPreparation.maxFileSize + 1))
    }

    func testMissingFileIsUnreadable() {
        let check = MediaDrop.isSendable(temporaryFile("png"))
        XCTAssertFalse(check.ok)
        XCTAssertEqual(check.reason, .unreadable)
    }

    func testSendDroppedFileAppendsImage() async throws {
        let pane = try await makePane()
        let url = temporaryFile("png")
        try pngData().write(to: url)
        let before = Self.imageCount(pane)
        await MediaDrop.send(urls: [url], imageData: [], through: pane.composer)
        await waitUntil { Self.imageCount(pane) > before }
        XCTAssertEqual(Self.imageCount(pane), before + 1)
        XCTAssertTrue(Self.lastMessageIsOwnImage(pane))
        XCTAssertNil(pane.composer.errorMessage)
    }

    func testSendPastedImageAppendsImageAndCleansUp() async throws {
        let pane = try await makePane()
        let filesBefore = Set(outgoingFiles())
        let before = Self.imageCount(pane)
        await MediaDrop.send(urls: [], imageData: [try pngData()], through: pane.composer)
        await waitUntil { Self.imageCount(pane) > before }
        XCTAssertEqual(Self.imageCount(pane), before + 1)
        XCTAssertTrue(Self.lastMessageIsOwnImage(pane))
        XCTAssertTrue(Set(outgoingFiles()).subtracting(filesBefore).isEmpty)
    }
}
