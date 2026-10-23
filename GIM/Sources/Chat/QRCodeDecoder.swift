import CoreGraphics
import Foundation
import ImageIO
import Vision

/// Reads the payloads of the QR codes in an image.
enum QRCodeDecoder {
    enum DecodeError: Error {
        case unreadableImage
    }

    /// Runs Vision on the caller's executor; call it off the main actor.
    nonisolated static func payloads(in image: CGImage) async throws -> [String] {
        try detect(in: image)
    }

    /// Decodes PNG, JPEG or TIFF `data` and reads its QR codes off the main actor.
    nonisolated static func payloads(in data: Data) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else { throw DecodeError.unreadableImage }
            return try detect(in: image)
        }.value
    }

    private nonisolated static func detect(in image: CGImage) throws -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try VNImageRequestHandler(cgImage: image).perform([request])
        return (request.results ?? []).compactMap(\.payloadStringValue)
    }
}
