import Foundation

/// What a web page says about itself, shown as a card under a message that links to it.
struct LinkPreview: Codable, Hashable, Sendable {
    var url: URL
    var title: String?
    var description: String?
    var imageURL: URL?
    var siteName: String?
    var fetchedAt: Date

    /// No title and no description: nothing worth a card. Also how a failed fetch is cached.
    var isEmpty: Bool {
        title == nil && description == nil
    }
}

enum LinkDetector {
    private static let trailingPunctuation: Set<Character> = [".", ",", ";", ":", "!", "?", "'", "\""]

    /// The first `http`/`https` URL in `text`, without trailing punctuation.
    static func firstURL(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        for match in detector.matches(in: text, range: range) {
            guard let url = match.url, isWeb(url) else { continue }
            var string = url.absoluteString
            while let last = string.last, trailingPunctuation.contains(last) {
                string.removeLast()
            }
            if let trimmed = URL(string: string), isWeb(trimmed) {
                return trimmed
            }
        }
        return nil
    }

    static func isWeb(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return false }
        return url.host?.isEmpty == false
    }
}
