import Foundation
import SwiftUI

/// The text of a message, selectable, with web links made clickable. Markdown is not interpreted.
struct TextBubble: View {
    let text: String

    var body: some View {
        Text(Self.linked(text))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// `text` with a `.link` attribute on every URL `NSDataDetector` finds.
    static func linked(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return result
        }
        let range = NSRange(text.startIndex..., in: text)
        for match in detector.matches(in: text, range: range) {
            guard let url = match.url, let textRange = Range(match.range, in: text),
                let lower = AttributedString.Index(textRange.lowerBound, within: result),
                let upper = AttributedString.Index(textRange.upperBound, within: result)
            else { continue }
            result[lower..<upper].link = url
            result[lower..<upper].underlineStyle = Text.LineStyle.single
        }
        return result
    }
}
