// The restore screen's input logic: a pasted recovery kit fills the Account ID and recovery key fields, and the
// fields get inline checks before the restore is sent.

import Foundation

enum RestoreInput {
    struct Fields: Hashable {
        var userId: String
        var recoveryCode: String
    }

    /// What a paste found in the text.
    enum Outcome: Hashable {
        case filledBoth
        case filledUserIdOnly
        case filledCodeOnly
        case nothingFound
    }

    /// Fills each field `RecoveryKit.parse` found in `pasted` (user ID lowercase, code grouped by four); a field
    /// that was not found keeps its value.
    static func apply(pasted: String, to fields: Fields) -> (fields: Fields, outcome: Outcome) {
        let parsed = RecoveryKit.parse(pasted)
        var result = fields
        if let userId = parsed.userId { result.userId = userId.lowercased() }
        if let symbols = parsed.recoveryCode { result.recoveryCode = RecoveryKit.formatRecoveryCode(symbols) }
        let outcome: Outcome =
            switch (parsed.userId != nil, parsed.recoveryCode != nil) {
            case (true, true): .filledBoth
            case (true, false): .filledUserIdOnly
            case (false, true): .filledCodeOnly
            case (false, false): .nothingFound
            }
        return (result, outcome)
    }

    /// The catalog key of the user ID field's inline error; nil while empty or valid.
    static func userIdMessageKey(_ raw: String) -> String? {
        let userId = RecoveryKit.normalizeUserId(raw)
        return userId.isEmpty || RecoveryKit.isValidUserId(userId) ? nil : "onboarding.restore.errorUserId"
    }

    /// The catalog key of the recovery key field's inline error; nil while empty, still being typed or valid.
    static func recoveryCodeMessageKey(_ raw: String) -> String? {
        RecoveryKit.isBrokenRecoveryCode(RecoveryKit.normalizeRecoveryCode(raw)) ? "onboarding.restore.errorCode" : nil
    }

    static func canSubmit(_ fields: Fields) -> Bool {
        RecoveryKit.isValidUserId(RecoveryKit.normalizeUserId(fields.userId))
            && RecoveryKit.isValidRecoveryCode(RecoveryKit.normalizeRecoveryCode(fields.recoveryCode))
    }
}
