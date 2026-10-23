import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

final class SidebarRowModelTests: XCTestCase {
    func testRowFromDirectChat() {
        let now = Date(timeIntervalSince1970: 1_761_210_000)
        let preview = MessagePreview(
            senderName: "Sofia Marin", text: "See you at the marina", sentAtMs: 1_761_209_940_000, isOwn: false)
        let summary = ChatSummary(
            chatId: "chat-sofia", kind: .direct, name: "Sofia Marin", avatar: nil, lastMessage: preview,
            unreadCount: 3, updatedAtMs: preview.sentAtMs, memberCount: 2, state: .active)
        let row = ChatRow(summary: summary, dateFormatter: RelativeDateFormatter(now: { now }))
        let model = SidebarRowModel(row: row, subtitle: row.preview ?? "")

        XCTAssertEqual(model.id, "chat-sofia")
        XCTAssertEqual(model.kind, .direct)
        XCTAssertEqual(model.title, "Sofia Marin")
        XCTAssertEqual(model.initials, "SM")
        XCTAssertEqual(model.unreadText, "3")
        XCTAssertEqual(model.subtitle, "See you at the marina")
        XCTAssertNotNil(model.time)
        XCTAssertEqual(model.colorIndex, SidebarRowModel.colorIndex(for: "chat-sofia"))
    }

    func testColorIndexIsStableAndInPalette() {
        let first = SidebarRowModel.colorIndex(for: "chat-sofia")
        let second = SidebarRowModel.colorIndex(for: "chat-sofia")
        XCTAssertEqual(first, second)
        XCTAssertTrue((0..<7).contains(first))
        XCTAssertEqual(DesignTokens.avatarPalette.count, 7)
        XCTAssertTrue((0..<7).contains(SidebarRowModel.colorIndex(for: "chat-crew")))
        XCTAssertTrue((0..<7).contains(SidebarRowModel.colorIndex(for: "")))
    }

    func testInitials() {
        XCTAssertEqual(SidebarRowModel.initials(for: "Aegean Crew"), "AC")
        XCTAssertEqual(SidebarRowModel.initials(for: "sofia"), "S")
        XCTAssertEqual(SidebarRowModel.initials(for: "  Nikos  Papadopoulos  Jr "), "NP")
        XCTAssertEqual(SidebarRowModel.initials(for: ""), "?")
        XCTAssertEqual(SidebarRowModel.initials(for: "   "), "?")
    }
}
