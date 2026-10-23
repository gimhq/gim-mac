import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// Renders `text` as a QR code, one pixel per module scaled without smoothing so it stays crisp. Exposes `text` as the
/// accessibility value so UI tests can read it.
struct QRCodeImage: View {
    let text: String

    var body: some View {
        Group {
            if let image = Self.makeImage(text) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("onboarding.link.qrLabel", tableName: "Onboarding"))
        .accessibilityValue(text)
    }

    static func makeImage(_ text: String) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
            let cgImage = CIContext().createCGImage(output, from: output.extent)
        else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

#Preview {
    QRCodeImage(text: "gim-link:fake:1")
        .frame(width: 220, height: 220)
}
