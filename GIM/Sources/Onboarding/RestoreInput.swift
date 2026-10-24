// The restore screen's format checks: inline messages for the Account ID and recovery key fields, and whether the
// pair can be sent. GIMFeatures only checks that the fields are not empty.

import Foundation

enum RestoreInput {
    /// The catalog key of the user ID field's inline error; nil while empty or valid.
    static func userIdMessageKey(_ raw: String) -> String? {
        let userId = RecoveryKit.normalizeUserId(raw)
        return userId.isEmpty || RecoveryKit.isValidUserId(userId) ? nil : "onboarding.restore.errorUserId"
    }

    /// The catalog key of the recovery key field's inline error; nil while empty, still being typed or valid.
    static func recoveryCodeMessageKey(_ raw: String) -> String? {
        RecoveryKit.isBrokenRecoveryCode(RecoveryKit.normalizeRecoveryCode(raw)) ? "onboarding.restore.errorCode" : nil
    }

    static func canSubmit(userId: String, recoveryCode: String) -> Bool {
        RecoveryKit.isValidUserId(RecoveryKit.normalizeUserId(userId))
            && RecoveryKit.isValidRecoveryCode(RecoveryKit.normalizeRecoveryCode(recoveryCode))
    }
}
