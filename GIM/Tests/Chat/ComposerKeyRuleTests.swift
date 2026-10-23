import AppKit
import XCTest

@testable import GIM

/// Which key press in the composer sends, inserts a newline or edits the last message.
final class ComposerKeyRuleTests: XCTestCase {
    private func action(
        _ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags = [], isTextEmpty: Bool = false
    ) -> ComposerKeyRule.Action {
        ComposerKeyRule.action(keyCode: keyCode, modifiers: modifiers, isTextEmpty: isTextEmpty)
    }

    func testReturnSends() {
        XCTAssertEqual(action(36), .send)
    }

    func testShiftReturnInsertsNewline() {
        XCTAssertEqual(action(36, .shift), .newline)
    }

    func testOptionReturnInsertsNewline() {
        XCTAssertEqual(action(36, .option), .newline)
    }

    func testKeypadEnterSends() {
        XCTAssertEqual(action(76, .numericPad), .send)
    }

    func testUpArrowInEmptyTextEditsLastMessage() {
        XCTAssertEqual(action(126, [.numericPad, .function], isTextEmpty: true), .editLastMessage)
    }

    func testUpArrowWithTextPassesThrough() {
        XCTAssertEqual(action(126, [.numericPad, .function], isTextEmpty: false), .passThrough)
    }

    func testLetterKeyPassesThrough() {
        XCTAssertEqual(action(0, isTextEmpty: true), .passThrough)
        XCTAssertEqual(action(0, .shift), .passThrough)
    }
}
