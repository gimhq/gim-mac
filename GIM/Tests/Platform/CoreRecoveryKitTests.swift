import GIMClientKit
import XCTest

@testable import GIM

final class CoreRecoveryKitTests: XCTestCase {
    /// The pure-Swift copy in GIMClientKit, which the onboarding tests use, must stay in step with gim-core.
    func testFakeRecoveryKitFunctionsMatchGimCore() {
        let core = CoreRecoveryKitFunctions()
        let fake = FakeRecoveryKitFunctions()
        let userId = "u" + String(String(repeating: "abcdefghijklmnopqrstuvwxyz234567", count: 2).prefix(54)) + "q"
        let code = "7BQ2-K9MX-4TVA-0HZR-PC63-W8NE-1SJD-5GFY-QK2M-V7R"
        let english = RecoveryKitLabels(
            title: "Recovery kit", accountId: "Account ID", recoveryKey: "Recovery key", note: "Keep this safe.")
        let chinese = RecoveryKitLabels(
            title: "恢复工具包", accountId: "账户 ID", recoveryKey: "恢复密钥", note: "请妥善保管。")

        for labels in [english, chinese] {
            for (userId, code) in [(userId, code), (" \(userId.uppercased()) ", code.lowercased()), ("", "a-b c")] {
                XCTAssertEqual(
                    core.formatRecoveryKit(userId: userId, recoveryCode: code, labels: labels),
                    fake.formatRecoveryKit(userId: userId, recoveryCode: code, labels: labels))
            }
        }
        let spaced = code.replacingOccurrences(of: "-", with: " ")
        let texts = [
            core.formatRecoveryKit(userId: userId, recoveryCode: code, labels: english),
            core.formatRecoveryKit(userId: userId, recoveryCode: code, labels: chinese),
            "账户 ID：\(userId)\n恢复密钥：\(code)\n",
            "Hi,\r\nAccount ID: \(userId.uppercased())\r\nmy key is \(spaced) again.\r\n",
            "\(userId) \(code.replacingOccurrences(of: "-", with: "").lowercased())",
            "\(userId)-0000", "\(userId)-\(code)", "x\(userId)", "\(userId)\n\(code.dropLast())S",
            "\(userId)\n\(code.replacingOccurrences(of: "0HZR", with: "OHZR"))", "my key is \(code)", "", "  \n\t ",
            "not a kit",
        ]
        for text in texts {
            XCTAssertEqual(core.parseRecoveryKit(text: text), fake.parseRecoveryKit(text: text), text)
        }
        for code in [code, code.lowercased(), "a-b", "", "ABCDE\u{301}"] {
            XCTAssertEqual(core.recoveryKeyEnding(recoveryCode: code), fake.recoveryKeyEnding(recoveryCode: code))
        }
        for typed in ["V7R", "MV7R", "mv-7r", " m v 7 r ", "MV7S", "AMV7R", ""] {
            XCTAssertEqual(
                core.matchesRecoveryKeyEnding(recoveryCode: code, typed: typed),
                fake.matchesRecoveryKeyEnding(recoveryCode: code, typed: typed), typed)
        }
    }
}
