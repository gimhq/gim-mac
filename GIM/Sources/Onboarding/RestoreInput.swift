// The restore screen's format checks: inline messages for the Account ID and recovery key fields, and whether the
// pair can be sent. GIMFeatures only checks that the fields are not empty, and `RecoveryKitFunctions` has no field
// validation (nor a check for a code still being typed), so the user ID and code shapes from gim-core
// docs/identity.md ("Identifiers", "Recovery backup") are checked here.

import Foundation

enum RestoreInput {
    /// 24 bytes in Crockford base32.
    private static let recoveryCodeSymbols = 39
    private static let crockfordAlphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    /// The catalog key of the user ID field's inline error; nil while empty or valid.
    static func userIdMessageKey(_ raw: String) -> String? {
        let userId = normalizeUserId(raw)
        return userId.isEmpty || isValidUserId(userId) ? nil : "onboarding.restore.errorUserId"
    }

    /// The catalog key of the recovery key field's inline error; nil while empty, still being typed or valid.
    static func recoveryCodeMessageKey(_ raw: String) -> String? {
        isBrokenRecoveryCode(normalizeRecoveryCode(raw)) ? "onboarding.restore.errorCode" : nil
    }

    static func canSubmit(userId: String, recoveryCode: String) -> Bool {
        isValidUserId(normalizeUserId(userId)) && isValidRecoveryCode(normalizeRecoveryCode(recoveryCode))
    }

    /// What the user typed, trimmed and lowercased (ids are canonical lowercase).
    private static func normalizeUserId(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// `"u"` + base32 (RFC 4648, lowercase, unpadded) of 34 bytes: 55 symbols, the last carrying 3 zero bits.
    private static func isValidUserId(_ value: String) -> Bool {
        value.wholeMatch(of: /u[a-z2-7]{54}[aiqy]/) != nil
    }

    /// The recovery code's symbols as gim-core reads them: `-` and whitespace dropped, uppercased, `I`/`L` -> `1`
    /// and `O` -> `0`. Other characters are kept so they can be flagged.
    private static func normalizeRecoveryCode(_ value: String) -> String {
        let kept = value.filter { $0 != "-" && !$0.isWhitespace }.uppercased()
        return String(
            kept.map { character -> Character in
                switch character {
                case "I", "L": "1"
                case "O": "0"
                default: character
                }
            })
    }

    /// `symbols` (from `normalizeRecoveryCode`) is a whole code: 39 symbols, the last one's 3 padding bits zero.
    private static func isValidRecoveryCode(_ symbols: String) -> Bool {
        guard symbols.count == recoveryCodeSymbols, symbols.allSatisfy({ crockfordAlphabet.contains($0) }),
            let last = symbols.last, let index = crockfordAlphabet.firstIndex(of: last)
        else { return false }
        return crockfordAlphabet.distance(from: crockfordAlphabet.startIndex, to: index) % 8 == 0
    }

    /// `symbols` cannot become a valid code by typing more: a foreign character, too long, or bad padding.
    private static func isBrokenRecoveryCode(_ symbols: String) -> Bool {
        symbols.contains { !crockfordAlphabet.contains($0) } || symbols.count > recoveryCodeSymbols
            || (symbols.count == recoveryCodeSymbols && !isValidRecoveryCode(symbols))
    }
}
