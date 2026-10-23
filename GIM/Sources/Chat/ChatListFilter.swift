import Foundation

/// Matches a chat list row against the sidebar's search text.
enum ChatListFilter {
    /// True when every word of `query` appears in the title or the subtitle; an empty query matches everything.
    static func matches(title: String, subtitle: String?, query: String) -> Bool {
        let words = normalized(query).split(separator: " ")
        guard !words.isEmpty else { return true }
        let title = normalized(title)
        let subtitle = subtitle.map(normalized) ?? ""
        return words.allSatisfy { title.contains($0) || subtitle.contains($0) }
    }

    /// `text` without case and diacritics, with runs of whitespace collapsed to one space.
    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
