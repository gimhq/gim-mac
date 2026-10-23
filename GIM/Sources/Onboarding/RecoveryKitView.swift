import AppKit
import GIMFeatures
import SwiftUI

/// Shows the recovery kit once, then has the user type the last four symbols of the recovery key back.
struct RecoveryKitView: View {
    @Bindable var viewModel: RecoveryCodeViewModel
    let userId: String
    @State private var typed = ""
    @State private var checkFailed = false
    @State private var copied = false
    @State private var saveError: String?

    init(viewModel: RecoveryCodeViewModel, userId: String) {
        self.viewModel = viewModel
        self.userId = userId
    }

    /// The kit words from the String Catalog.
    static func labels() -> RecoveryKitLabels {
        RecoveryKitLabels(
            title: String(localized: "onboarding.kit.fileTitle", table: "Onboarding"),
            accountId: String(localized: "onboarding.kit.accountId", table: "Onboarding"),
            recoveryKey: String(localized: "onboarding.kit.recoveryKey", table: "Onboarding"),
            note: String(localized: "onboarding.kit.fileNote", table: "Onboarding"))
    }

    /// `typed` is the last four symbols of `code`.
    static func endingMatches(code: String, typed: String) -> Bool {
        RecoveryKit.matchesRecoveryKeyEnding(code, typed: typed)
    }

    private var kitText: String {
        RecoveryKit.format(userId: userId, recoveryCode: viewModel.code ?? "", labels: Self.labels())
    }

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isConfirming {
                check
            } else {
                kit
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var kit: some View {
        Text("onboarding.kit.title", tableName: "Onboarding")
            .font(.title2.bold())
        Text("onboarding.kit.body", tableName: "Onboarding")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        Text(kitText)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
        if let saveError {
            Text(saveError)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
        HStack {
            Button(action: copy) {
                if copied {
                    Text("onboarding.kit.copied", tableName: "Onboarding")
                } else {
                    Text("onboarding.kit.copy", tableName: "Onboarding")
                }
            }
            Button {
                saveError = RecoveryKitFile.save(kitText)
            } label: {
                Text("onboarding.kit.saveFile", tableName: "Onboarding")
            }
            Button {
                typed = ""
                checkFailed = false
                viewModel.continueToConfirmation()
            } label: {
                Text("onboarding.kit.saved", tableName: "Onboarding")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    @ViewBuilder
    private var check: some View {
        Text("onboarding.kit.checkTitle", tableName: "Onboarding")
            .font(.title2.bold())
        Text("onboarding.kit.checkBody", tableName: "Onboarding")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        VStack(alignment: .leading, spacing: 4) {
            TextField(text: $typed) {
                Text("onboarding.kit.checkLabel", tableName: "Onboarding")
            }
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            if checkFailed {
                Text("onboarding.kit.checkError", tableName: "Onboarding")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        HStack {
            Button {
                viewModel.showCodeAgain()
            } label: {
                Text("onboarding.kit.showAgain", tableName: "Onboarding")
            }
            .keyboardShortcut(.cancelAction)
            Button(action: confirm) {
                Text("onboarding.kit.confirm", tableName: "Onboarding")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    /// The Mac flow checks the key's last four symbols; the view model's group check is satisfied with the group it
    /// asks for, which is never shown.
    private func confirm() {
        guard let code = viewModel.code, Self.endingMatches(code: code, typed: typed) else {
            checkFailed = true
            return
        }
        let groups = viewModel.groups
        guard groups.indices.contains(viewModel.confirmationGroupIndex) else { return }
        viewModel.confirmationInput = groups[viewModel.confirmationGroupIndex]
        viewModel.confirm()
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(kitText, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }
}
