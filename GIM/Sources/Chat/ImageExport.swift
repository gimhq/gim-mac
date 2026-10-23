import AppKit
import GIMFeatures

/// Turns an image from the pasteboard or a drop into a file that can be sent: downscaled to
/// `MediaPreparation.maxImagePixelSize`, JPEG unless it has transparency, then PNG.
enum ImageExport {
    /// JPEG data of `image`, its longest side at most `maxLongestSide`.
    static func jpegData(
        from image: NSImage, maxLongestSide: Int = MediaPreparation.maxImagePixelSize,
        quality: Double = MediaPreparation.imageCompressionQuality
    ) -> Data? {
        guard let rep = scaledBitmap(of: image, maxLongestSide: maxLongestSide) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }

    /// Encoded data and file extension of `image`: PNG when it has transparency, JPEG otherwise.
    static func data(
        from image: NSImage, maxLongestSide: Int = MediaPreparation.maxImagePixelSize,
        quality: Double = MediaPreparation.imageCompressionQuality
    ) -> (data: Data, fileExtension: String)? {
        guard let rep = scaledBitmap(of: image, maxLongestSide: maxLongestSide) else { return nil }
        if rep.hasAlpha, hasTransparency(image) {
            return rep.representation(using: .png, properties: [:]).map { ($0, "png") }
        }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality]).map { ($0, "jpg") }
    }

    /// Writes `data` to `gim-outgoing/<uuid>.<fileExtension>` in the temporary directory.
    static func writeTemporaryFile(_ data: Data, fileExtension: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gim-outgoing", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
        try data.write(to: url)
        return url
    }

    /// Size in pixels of the image's best representation.
    static func pixelSize(of image: NSImage) -> (width: Int, height: Int) {
        if let cgImage = cgImage(of: image) {
            return (cgImage.width, cgImage.height)
        }
        return (Int(image.size.width.rounded()), Int(image.size.height.rounded()))
    }

    /// The largest bitmap's pixels when there is one, so the screen's scale doesn't change the size.
    private static func cgImage(of image: NSImage) -> CGImage? {
        let bitmaps = image.representations.compactMap { $0 as? NSBitmapImageRep }
        if let cgImage = bitmaps.max(by: { $0.pixelsWide < $1.pixelsWide })?.cgImage {
            return cgImage
        }
        var rect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    private static func hasTransparency(_ image: NSImage) -> Bool {
        guard let alphaInfo = cgImage(of: image)?.alphaInfo else { return false }
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return false
        default: return true
        }
    }

    /// The image drawn into a bitmap of the target size.
    private static func scaledBitmap(of image: NSImage, maxLongestSide: Int) -> NSBitmapImageRep? {
        guard let source = cgImage(of: image), source.width > 0, source.height > 0 else { return nil }
        let target = MediaPreparation.targetImageSize(
            width: source.width, height: source.height, maxLongestSide: maxLongestSide)
        guard
            let context = CGContext(
                data: nil, width: target.width, height: target.height, bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: target.width, height: target.height))
        return context.makeImage().map { NSBitmapImageRep(cgImage: $0) }
    }
}
