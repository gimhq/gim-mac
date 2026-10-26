import AppKit
import GIMFeatures
import SwiftUI

/// Shows the recovery kit once, then has the user type the last four symbols of the recovery key back.
struct RecoveryKitView: View {
    @Bindable var viewModel: RecoveryKitViewModel
    @State private var copied = false
    @State private var saveError: String?

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isChecking {
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
        Text(viewModel.kitText)
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
                saveError = RecoveryKitFile.save(viewModel.kitText)
            } label: {
                Text("onboarding.kit.saveFile", tableName: "Onboarding")
            }
            Button {
                viewModel.continueToCheck()
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
            TextField(text: $viewModel.endingInput) {
                Text("onboarding.kit.checkLabel", tableName: "Onboarding")
            }
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            if let kind = viewModel.endingErrorKind {
                Text(kind.text)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        HStack {
            Button {
                viewModel.showKitAgain()
            } label: {
                Text("onboarding.kit.showAgain", tableName: "Onboarding")
            }
            .keyboardShortcut(.cancelAction)
            Button {
                viewModel.confirm()
            } label: {
                Text("onboarding.kit.confirm", tableName: "Onboarding")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(viewModel.kitText, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }
}
