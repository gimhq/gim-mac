import AppKit
import XCTest

@testable import GIM

/// `ImageExport`: downscaling to the sent size and the temporary file.
final class ImageExportTests: XCTestCase {
    /// An opaque image of exactly `width`×`height` pixels.
    private func makeImage(width: Int, height: Int) throws -> NSImage {
        let rep = try XCTUnwrap(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 3,
                hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.systemTeal.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        NSGraphicsContext.restoreGraphicsState()
        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(rep)
        return image
    }

    private func decodedPixelSize(_ data: Data) throws -> (width: Int, height: Int) {
        let rep = try XCTUnwrap(NSBitmapImageRep(data: data))
        return (rep.pixelsWide, rep.pixelsHigh)
    }

    func testLargeImageIsDownscaled() throws {
        let image = try makeImage(width: 4000, height: 2000)
        let data = try XCTUnwrap(ImageExport.jpegData(from: image))
        let size = try decodedPixelSize(data)
        XCTAssertEqual(size.width, 2048)
        XCTAssertEqual(size.height, 1024)
    }

    func testSmallImageKeepsItsSize() throws {
        let image = try makeImage(width: 100, height: 50)
        let export = try XCTUnwrap(ImageExport.data(from: image))
        XCTAssertEqual(export.fileExtension, "jpg")
        let size = try decodedPixelSize(export.data)
        XCTAssertEqual(size.width, 100)
        XCTAssertEqual(size.height, 50)
        XCTAssertEqual(ImageExport.pixelSize(of: image).width, 100)
        XCTAssertEqual(ImageExport.pixelSize(of: image).height, 50)
    }

    func testWriteTemporaryFile() throws {
        let url = try ImageExport.writeTemporaryFile(Data([1, 2, 3]), fileExtension: "png")
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(url.pathExtension, "png")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "gim-outgoing")
    }
}
