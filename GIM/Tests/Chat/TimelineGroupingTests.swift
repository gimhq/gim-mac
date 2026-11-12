import GIMClientKit
import GIMFeatures
import XCTest

@testable import GIM

/// Runs, tails, sender names and day chips from `TimelineItemBuilder`, plus `TimelineRowLayout` and prepend detection.
final class TimelineGroupingTests: XCTestCase {
    private let minute: UInt64 = 60_000
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    /// 2026-10-23 12:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_792_756_800)

    private var dayStartMs: UInt64 {
        UInt64(calendar.startOfDay(for: now).timeIntervalSince1970 * 1000)
    }

    /// A morning time of the fixed day.
    private func at(minutes: UInt64) -> UInt64 {
        dayStartMs + 9 * 60 * minute + minutes * minute
    }

    private func builder() -> TimelineItemBuilder {
        let now = now
        return TimelineItemBuilder(calendar: calendar, locale: Locale(identifier: "en_US_POSIX"), now: { now })
    }

    private func message(_ id: String, from senderId: String, at sentAtMs: UInt64, isOwn: Bool = false)
        -> TimelineItem
    {
        .message(
            item: MessageItem(
                messageId: id, chatId: "chat-test",
                sender: UserProfile(userId: senderId, displayName: senderId.capitalized),
                isOwn: isOwn, sentAtMs: sentAtMs, content: .text(body: "Hello"), replyTo: nil, reactions: [],
                edited: false, sendState: isOwn ? .sent : nil))
    }

    private func rows(_ items: [TimelineItem], isGroup: Bool = false) -> [TimelineMessageRow] {
        builder().build(items, isGroup: isGroup, typingText: nil).compactMap(\.messageRow)
    }

    func testSameSenderWithinFiveMinutesFormsOneRun() {
        let rows = rows([
            message("m1", from: "sofia", at: at(minutes: 0)),
            message("m2", from: "sofia", at: at(minutes: 1)),
        ])
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows[0].isFirstInRun)
        XCTAssertFalse(rows[0].hasTail)
        XCTAssertFalse(rows[1].isFirstInRun)
        XCTAssertTrue(rows[1].hasTail)
    }

    func testSixMinuteGapStartsANewRun() {
        let rows = rows([
            message("m1", from: "sofia", at: at(minutes: 0)),
            message("m2", from: "sofia", at: at(minutes: 6)),
        ])
        XCTAssertTrue(rows[0].hasTail)
        XCTAssertTrue(rows[1].isFirstInRun)
    }

    func testDifferentSenderStartsANewRun() {
        let rows = rows([
            message("m1", from: "sofia", at: at(minutes: 0)),
            message("m2", from: "luca", at: at(minutes: 1)),
        ])
        XCTAssertTrue(rows[0].hasTail)
        XCTAssertTrue(rows[1].isFirstInRun)
    }

    func testSenderNameOnlyOnFirstRowOfRunInGroupsAndNeverForOwn() {
        let items = [
            message("m1", from: "sofia", at: at(minutes: 0)),
            message("m2", from: "sofia", at: at(minutes: 1)),
            message("m3", from: "alex", at: at(minutes: 2), isOwn: true),
            message("m4", from: "alex", at: at(minutes: 3), isOwn: true),
        ]
        let groupRows = rows(items, isGroup: true)
        XCTAssertEqual(groupRows.map(\.senderName), ["Sofia", nil, nil, nil])
        XCTAssertTrue(TimelineRowLayout.showsSenderName(row: groupRows[0]))
        XCTAssertFalse(TimelineRowLayout.showsSenderName(row: groupRows[1]))
        XCTAssertTrue(TimelineRowLayout.showsAvatar(row: groupRows[0], isGroup: true))
        XCTAssertFalse(TimelineRowLayout.showsAvatar(row: groupRows[1], isGroup: true))
        XCTAssertFalse(TimelineRowLayout.showsAvatar(row: groupRows[2], isGroup: true))
        XCTAssertEqual(TimelineRowLayout.alignment(for: groupRows[0]), .leading)
        XCTAssertEqual(TimelineRowLayout.alignment(for: groupRows[2]), .trailing)

        let directRows = rows(items, isGroup: false)
        XCTAssertTrue(directRows.allSatisfy { $0.senderName == nil })
        XCTAssertFalse(TimelineRowLayout.showsAvatar(row: directRows[0], isGroup: false))
    }

    func testDateSeparatorForTodayReadsToday() {
        let items = builder().build(
            [.dateSeparator(dayStartMs: dayStartMs), message("m1", from: "sofia", at: at(minutes: 0))],
            isGroup: false, typingText: nil)
        XCTAssertEqual(items.first?.kind, .dateSeparator("Today"))
    }

    func testSpacingAfterTailAndRunRows() {
        let rows = rows([
            message("m1", from: "sofia", at: at(minutes: 0)),
            message("m2", from: "sofia", at: at(minutes: 1)),
        ])
        XCTAssertEqual(TimelineRowLayout.spacingAfter(row: rows[0]), 2)
        XCTAssertEqual(TimelineRowLayout.spacingAfter(row: rows[1]), 12)
    }

    func testOlderPagePrependedIsAPrependWithoutReloads() {
        let separator = TimelineItem.dateSeparator(dayStartMs: dayStartMs)
        let newer = [
            message("m3", from: "sofia", at: at(minutes: 60)),
            message("m4", from: "sofia", at: at(minutes: 61)),
        ]
        let older = [
            message("m1", from: "luca", at: at(minutes: 0)),
            message("m2", from: "luca", at: at(minutes: 1)),
        ]
        let builder = builder()
        let old = builder.build([separator] + newer, isGroup: false, typingText: nil)
        let new = builder.build([separator] + older + newer, isGroup: false, typingText: nil)

        let change = TimelineChangeSet(from: old, to: new)
        XCTAssertTrue(change.isPrepend)
        XCTAssertEqual(change.insertedIds, ["msg:m1", "msg:m2"])
        XCTAssertEqual(change.reloadedIds, [])
        XCTAssertEqual(change.deletedIds, [])
    }
}
