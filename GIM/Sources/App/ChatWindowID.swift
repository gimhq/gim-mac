/// The value a chat window is opened for (`WindowGroup(id:for:)`).
struct ChatWindowID: Hashable, Codable, Sendable {
    let chatId: String

    static let windowGroupID = "chat"
}
