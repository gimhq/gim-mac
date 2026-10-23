import AppKit
import UniformTypeIdentifiers

/// Saves the recovery kit text as a plain text file the user picks.
enum RecoveryKitFile {
    static let defaultFileName = "gim-recovery-kit.txt"

    /// Asks where to save `text`; returns an error message when writing failed, nil when saved or cancelled.
    @MainActor
    static func save(_ text: String) -> String? {
        let panel = NSSavePanel()
        panel.title = String(localized: "onboarding.kit.saveFile", table: "Onboarding")
        panel.nameFieldStringValue = defaultFileName
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            try Data(text.utf8).write(to: url, options: .atomic)
            return nil
        } catch {
            return String(localized: "onboarding.kit.saveFailed", table: "Onboarding")
        }
    }
}
