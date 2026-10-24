import GIMFeatures
import SwiftUI

/// Restores the account from the recovery kit: one field for the pasted kit, which the view model parses into the
/// Account ID and recovery key fields; the fields can also be typed. After success it tells the user that old chats don't come back.
struct RestoreView: View {
    @State private var viewModel: RestoreViewModel
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
    }

    @ViewBuilder
    private var form: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("onboarding.restore.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            pasteField
            if viewModel.showsFields {
                manualFields
            } else {
                Button {
                    viewModel.enterSeparately()
                } label: {
                    Text("onboarding.restore.manualTitle", tableName: "Onboarding")
                }
                .buttonStyle(.link)
            }
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
                .disabled(
                    !RestoreInput.canSubmit(userId: viewModel.userId, recoveryCode: viewModel.recoveryCode)
                        || !viewModel.canSubmit)
            }
        }
    }

    private var pasteField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("onboarding.restore.pasteLabel", tableName: "Onboarding")
                .font(.headline)
            TextField(text: $viewModel.kitText, axis: .vertical) {
                Text("onboarding.restore.pasteLabel", tableName: "Onboarding")
            }
            .lineLimit(3...6)
            .font(.body.monospaced())
            .accessibilityLabel(Text("onboarding.restore.pasteLabel", tableName: "Onboarding"))
            helpText("onboarding.restore.pasteHelp")
            switch viewModel.kitErrorKind {
            case .kitNotRecognized:
                errorText("onboarding.restore.errorNotRecognized")
            case .kitPartMissing:
                errorText("onboarding.restore.errorIncomplete")
            default:
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
}
