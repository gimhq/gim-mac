import GIMFeatures
import SwiftUI

/// The optional last create-account step: a username friends can find the user by.
struct ClaimHandleView: View {
    @Bindable var viewModel: ClaimHandleViewModel

    init(viewModel: ClaimHandleViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("onboarding.username.title", tableName: "Onboarding")
                    .font(.title2.bold())
                Text("onboarding.username.body", tableName: "Onboarding")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 4) {
                TextField(text: $viewModel.handle) {
                    Text("onboarding.username.label", tableName: "Onboarding")
                }
                .textContentType(.username)
                .autocorrectionDisabled()
                Text("onboarding.username.help", tableName: "Onboarding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let kind = viewModel.handleErrorKind {
                    Text(kind.text)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            if let kind = viewModel.errorKind {
                Text(kind.text)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button {
                    Task { await viewModel.skip() }
                } label: {
                    Text("onboarding.username.skip", tableName: "Onboarding")
                }
                .keyboardShortcut(.cancelAction)
                .disabled(viewModel.isSubmitting)
                Button {
                    Task { await viewModel.claim() }
                } label: {
                    Text("onboarding.username.save", tableName: "Onboarding")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.canClaim)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
