import Foundation
import GIMFeatures
import Observation

/// Find in chat: the query, the matching messages of the loaded timeline and the current match.
@MainActor
@Observable
final class ChatSearch {
    var isActive = false
    /// The pane re-runs `update(items:)` when this changes.
    var query = ""
    /// Ids of the matching messages, in timeline order.
    private(set) var matchIds: [String] = []
    private(set) var currentIndex: Int?

    var currentMatchId: String? {
        currentIndex.map { matchIds[$0] }
    }

    /// "n of m", "No matches", or nil while the query is empty.
    var countText: String? {
        guard !ChatListFilter.normalized(query).isEmpty else { return nil }
        guard let currentIndex else {
            return String(localized: "chat.search.none", defaultValue: "No matches", table: "Chat")
        }
        return String(
            localized: "chat.search.count", defaultValue: "\(currentIndex + 1) of \(matchIds.count)", table: "Chat")
    }

    /// Recomputes the matches; keeps the current match while it still matches, else moves to the newest one.
    func update(items: [TimelineDisplayItem]) {
        let previousId = currentMatchId
        matchIds = Self.matchIds(in: items, query: query)
        if let previousId, let index = matchIds.firstIndex(of: previousId) {
            currentIndex = index
        } else {
            currentIndex = matchIds.isEmpty ? nil : matchIds.count - 1
        }
    }

    func next() {
        guard let currentIndex, !matchIds.isEmpty else { return }
        self.currentIndex = (currentIndex + 1) % matchIds.count
    }

    func previous() {
        guard let currentIndex, !matchIds.isEmpty else { return }
        self.currentIndex = (currentIndex - 1 + matchIds.count) % matchIds.count
    }

    func activate() {
        isActive = true
    }

    func close() {
        query = ""
        matchIds = []
        currentIndex = nil
        isActive = false
    }

    static func matchIds(in items: [TimelineDisplayItem], query: String) -> [String] {
        guard !ChatListFilter.normalized(query).isEmpty else { return [] }
        return items.compactMap(\.messageRow)
            .filter { matches($0, query: query) }
            .map(\.message.messageId)
    }

    /// True when every query word appears in the row's text, caption or file name; placeholders never match.
    static func matches(_ row: TimelineMessageRow, query: String) -> Bool {
        let fields: [String]
        switch row.body {
        case .text(let text):
            fields = [text]
        case .image(_, _, _, let caption):
            fields = [caption ?? ""]
        case .file(_, let fileName, _, let caption):
            fields = [fileName, caption ?? ""]
        case .placeholder:
            return false
        }
        let words = ChatListFilter.normalized(query).split(separator: " ")
        guard !words.isEmpty else { return false }
        let text = fields.map(ChatListFilter.normalized).joined(separator: "\n")
        return words.allSatisfy { text.contains($0) }
    }
}
