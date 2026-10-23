import GIMFeatures
import SwiftUI

/// Restores the account from the recovery kit: one field for the pasted kit, with the Account ID and recovery key
/// fields as the fallback. After success it tells the user that old chats don't come back.
struct RestoreView: View {
    @State private var viewModel: RestoreViewModel
    @State private var pasted = ""
    @State private var pasteOutcome: RestoreInput.Outcome?
    private let onLeave: () -> Void

    init(context: OnboardingContext, onLeave: @escaping () -> Void) {
        _viewModel = State(initialValue: RestoreViewModel(context: context))
        self.onLeave = onLeave
    }

    var body: some View {
        Group {
            if viewModel.showsRejoinNotice {
                done
            } else {
                ScrollView {
                    form
                        .padding(24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(Text("onboarding.restore.title", tableName: "Onboarding"))
        .navigationBarBackButtonHidden(true)
        .onChange(of: pasted) { _, text in
            applyPaste(text)
        }
    }

    private var fields: RestoreInput.Fields {
        RestoreInput.Fields(userId: viewModel.userId, recoveryCode: viewModel.recoveryCode)
    }

    @ViewBuilder
    private var form: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("onboarding.restore.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            pasteField
            manualFields
            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: $viewModel.revokeOthers) {
                    Text("onboarding.restore.revokeOthers", tableName: "Onboarding")
                }
                helpText("onboarding.restore.revokeOthersHelp")
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                Button {
                    onLeave()
                } label: {
                    Text("onboarding.restore.cancel", tableName: "Onboarding")
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isSubmitting {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("onboarding.restore.submitting", tableName: "Onboarding")
                        }
                    } else {
                        Text("onboarding.restore.submit", tableName: "Onboarding")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!RestoreInput.canSubmit(fields) || !viewModel.canSubmit)
            }
        }
    }

    private var pasteField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("onboarding.restore.pasteLabel", tableName: "Onboarding")
                .font(.headline)
            TextEditor(text: $pasted)
                .font(.body.monospaced())
                .frame(height: 72)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(.background, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
                .accessibilityLabel(Text("onboarding.restore.pasteLabel", tableName: "Onboarding"))
            helpText("onboarding.restore.pasteHelp")
            switch pasteOutcome {
            case .nothingFound:
                errorText("onboarding.restore.errorNotRecognized")
            case .filledUserIdOnly, .filledCodeOnly:
                errorText("onboarding.restore.errorIncomplete")
            case .filledBoth, nil:
                EmptyView()
            }
        }
    }

    private var manualFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("onboarding.restore.manualTitle", tableName: "Onboarding")
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                TextField(text: $viewModel.userId) {
                    Text("onboarding.restore.userIdLabel", tableName: "Onboarding")
                }
                .autocorrectionDisabled()
                helpText("onboarding.restore.userIdHelp")
                if let key = RestoreInput.userIdMessageKey(viewModel.userId) {
                    errorText(key)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                TextField(text: $viewModel.recoveryCode) {
                    Text("onboarding.restore.codeLabel", tableName: "Onboarding")
                }
                .font(.body.monospaced())
                .autocorrectionDisabled()
                helpText("onboarding.restore.codeHelp")
                if let key = RestoreInput.recoveryCodeMessageKey(viewModel.recoveryCode) {
                    errorText(key)
                }
            }
        }
    }

    private var done: some View {
        VStack(spacing: 16) {
            Text("onboarding.restore.doneTitle", tableName: "Onboarding")
                .font(.title2.bold())
            Text("onboarding.restore.doneBody", tableName: "Onboarding")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                viewModel.finish()
            } label: {
                Text("onboarding.restore.continue", tableName: "Onboarding")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
    }

    private func helpText(_ key: String) -> some View {
        Text(LocalizedStringKey(key), tableName: "Onboarding")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func errorText(_ key: String) -> some View {
        Text(LocalizedStringKey(key), tableName: "Onboarding")
            .font(.caption)
            .foregroundStyle(.red)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Fills the fields from the pasted kit; clearing the paste field clears only its message.
    private func applyPaste(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            pasteOutcome = nil
            return
        }
        let (filled, outcome) = RestoreInput.apply(pasted: text, to: fields)
        viewModel.userId = filled.userId
        viewModel.recoveryCode = filled.recoveryCode
        pasteOutcome = outcome
    }
}
