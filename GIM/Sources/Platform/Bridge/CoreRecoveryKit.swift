import Foundation
import GIMClientKit
import GIMCore

/// gim-core's recovery-kit free functions behind `RecoveryKitFunctions`. The two structs are converted inline: they are
/// field-for-field copies of their GIMCore counterparts.
struct CoreRecoveryKitFunctions: RecoveryKitFunctions {
    func formatRecoveryKit(userId: String, recoveryCode: String, labels: GIMClientKit.RecoveryKitLabels) -> String {
        GIMCore.formatRecoveryKit(
            userId: userId, recoveryCode: recoveryCode,
            labels: GIMCore.RecoveryKitLabels(
                title: labels.title, accountId: labels.accountId, recoveryKey: labels.recoveryKey, note: labels.note))
    }

    func parseRecoveryKit(text: String) -> GIMClientKit.ParsedRecoveryKit {
        let parsed = GIMCore.parseRecoveryKit(text: text)
        return GIMClientKit.ParsedRecoveryKit(userId: parsed.userId, recoveryCode: parsed.recoveryCode)
    }

    func recoveryKeyEnding(recoveryCode: String) -> String {
        GIMCore.recoveryKeyEnding(recoveryCode: recoveryCode)
    }

    func matchesRecoveryKeyEnding(recoveryCode: String, typed: String) -> Bool {
        GIMCore.matchesRecoveryKeyEnding(recoveryCode: recoveryCode, typed: typed)
    }
}
