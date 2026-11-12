import GIMClientKit
import GIMFeatures

/// One sidebar row: a `ChatRow` plus the subtitle `ChatListViewModel.subtitle(for:)` renders for it and the ticks of
/// `ChatListViewModel.lastMessageStatus(for:)`.
struct SidebarRowModel: Identifiable, Hashable, Sendable {
    let id: String
    let kind: ChatKind
    let title: String
    let subtitle: String
    let time: String?
    let unreadText: String?
    let initials: String
    let colorIndex: Int
    /// The note to self: the own avatar with a note badge.
    let isNoteToSelf: Bool
    /// Ticks of the own last message; `nil` for other people's messages or while its status is unknown.
    let sendTick: SendTick?

    /// `MessageStatus` without the failure reason, which the row never shows.
    enum SendTick: Hashable, Sendable {
        case sending
        case sent
        case delivered
        case read
        case failed
    }

    init(row: ChatRow, subtitle: String, status: MessageStatus?) {
        id = row.id
        kind = row.kind
        title = row.title
        self.subtitle = subtitle
        time = row.time
        unreadText = row.unreadText
        initials = Self.initials(for: row.avatarName)
        colorIndex = Self.colorIndex(for: row.avatarId)
        isNoteToSelf = row.isNoteToSelf
        sendTick = row.lastMessageIsOwn ? status.map(Self.sendTick(for:)) : nil
    }

    static func sendTick(for status: MessageStatus) -> SendTick {
        switch status {
        case .sending: .sending
        case .sent: .sent
        case .delivered: .delivered
        case .read: .read
        case .failed: .failed
        }
    }

    /// The first letter of the first two words, uppercased; "?" for an empty title.
    static func initials(for title: String) -> String {
        let letters = title.split(whereSeparator: \.isWhitespace).prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()
        return letters.isEmpty ? "?" : letters
    }

    /// Index into `DesignTokens.avatarPalette`: FNV-1a (32-bit) of the chat id, so the colour survives launches.
    static func colorIndex(for id: String) -> Int {
        var hash: UInt32 = 2_166_136_261
        for byte in id.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16_777_619
        }
        return Int(hash % UInt32(DesignTokens.avatarPalette.count))
    }
}
