import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Contract C8: the "My QR code" image encodes the plain Account ID and nothing else.
enum AccountQRCode {
    /// The QR payload: `accountId` exactly as given (no prefix, no URL, no trimming).
    static func payload(accountId: String) -> String {
        accountId
    }

    /// A square QR code (error correction "M") about `side` points wide, scaled with nearest-neighbour so the
    /// modules stay sharp; `nil` only if CoreImage fails.
    static func image(payload: String, side: CGFloat) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage, output.extent.width > 0 else { return nil }
        let scale = max(1, (side / output.extent.width).rounded(.down))
        let scaled = output.samplingNearest().transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let rep = NSCIImageRep(ciImage: scaled)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}
