// The restore screen's format checks: inline messages for the Account ID and recovery key fields, and whether the
// pair can be sent. GIMFeatures only checks that the fields are not empty, and `RecoveryKitFunctions` has no field
// validation (nor a check for a code still being typed), so the recovery code shape from gim-core docs/identity.md
// ("Recovery backup") is checked here; the user ID shape and the code normalization are GIMFeatures'.

import Foundation
import GIMFeatures

enum RestoreInput {
    /// 24 bytes in Crockford base32.
    private static let recoveryCodeSymbols = 39
    private static let crockfordAlphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

    /// The catalog key of the user ID field's inline error; nil while empty or valid.
    static func userIdMessageKey(_ raw: String) -> String? {
        UserID.normalized(raw).isEmpty || UserID.isValid(raw) ? nil : "onboarding.restore.errorUserId"
    }

    /// The catalog key of the recovery key field's inline error; nil while empty, still being typed or valid.
    static func recoveryCodeMessageKey(_ raw: String) -> String? {
        isBrokenRecoveryCode(RecoveryKit.normalizedRecoveryCode(raw)) ? "onboarding.restore.errorCode" : nil
    }

    static func canSubmit(userId: String, recoveryCode: String) -> Bool {
        UserID.isValid(userId) && isValidRecoveryCode(RecoveryKit.normalizedRecoveryCode(recoveryCode))
    }

    /// `symbols` (from `RecoveryKit.normalizedRecoveryCode`) is a whole code: 39 symbols, the last one's 3 padding
    /// bits zero.
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
