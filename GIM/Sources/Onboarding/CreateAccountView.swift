import GIMFeatures
import SwiftUI

/// The first create-account step: the display name. The server keeps the one from the start screen unless the user
/// opens "Use another server".
struct CreateAccountView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showsServer = false

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            if showsServer {
                serverStep
            } else if let createIdentity = viewModel.createIdentity {
                NameStep(createIdentity: createIdentity, onCancel: { viewModel.path = [] })
                Button {
                    showsServer = true
                } label: {
                    Text("onboarding.server.useAnother", tableName: "Onboarding")
                }
                .buttonStyle(.link)
                .font(.callout)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
    }

    private var serverStep: some View {
        VStack(spacing: 16) {
            ServerField(viewModel: viewModel)
            HStack {
                Button {
                    showsServer = false
                } label: {
                    Text("onboarding.server.keep", tableName: "Onboarding")
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    // Re-creates the context for the new address; the create route stays open.
                    viewModel.choose(.createIdentity)
                    if !viewModel.path.isEmpty { showsServer = false }
                } label: {
                    Text("onboarding.server.apply", tableName: "Onboarding")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.serverUrlError != nil)
            }
        }
    }
}

/// The display name form.
private struct NameStep: View {
    @Bindable var createIdentity: CreateIdentityViewModel
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 8) {
            Text("onboarding.create.nameTitle", tableName: "Onboarding")
                .font(.title2.bold())
            Text("onboarding.create.nameBody", tableName: "Onboarding")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        VStack(alignment: .leading, spacing: 4) {
            TextField(text: $createIdentity.displayName) {
                Text("onboarding.create.nameLabel", tableName: "Onboarding")
            }
            .textContentType(.name)
            if let error = createIdentity.displayNameError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        if let error = createIdentity.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        HStack {
            Button(action: onCancel) {
                Text("onboarding.create.cancel", tableName: "Onboarding")
            }
            .keyboardShortcut(.cancelAction)
            Button(action: submit) {
                if createIdentity.isSubmitting {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("onboarding.create.submitting", tableName: "Onboarding")
                    }
                } else {
                    Text("onboarding.create.submit", tableName: "Onboarding")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(!createIdentity.canSubmit)
        }
    }

    private func submit() {
        Task { await createIdentity.submit() }
    }
}
