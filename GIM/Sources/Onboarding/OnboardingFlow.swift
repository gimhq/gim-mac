import GIMClientKit
import GIMFeatures
import SwiftUI

/// Onboarding entry point: builds the onboarding view model from the app model and signs in with the client it
/// registered, linked or restored.
struct OnboardingFlow: View {
    let model: AppModel
    /// Formats, parses and checks the recovery kit; gim-core's functions unless a test or preview passes others.
    var recoveryKit: any RecoveryKitFunctions = CoreRecoveryKitFunctions()
    @State private var viewModel: OnboardingViewModel?
    @State private var errorText: String?

    var body: some View {
        Group {
            if let viewModel {
                OnboardingShellView(viewModel: viewModel)
            } else if let errorText {
                VStack(spacing: 12) {
                    Text(errorText)
                        .multilineTextAlignment(.center)
                    Button {
                        makeViewModelIfNeeded()
                    } label: {
                        Text("onboarding.flow.tryAgain", tableName: "Onboarding")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { makeViewModelIfNeeded() }
    }

    /// The onboarding view model for `model`: its server (`resolvedServerUrl()`), keep server, launch client and
    /// `signIn`.
    static func makeViewModel(model: AppModel, recoveryKit: any RecoveryKitFunctions) throws -> OnboardingViewModel {
        OnboardingViewModel(
            factory: model.clientFactory,
            hooks: try model.platformHooks(),
            recoveryKit: recoveryKit,
            serverUrl: model.resolvedServerUrl(),
            client: model.client,
            localStateReset: model.client?.localStateReset() ?? false,
            keepServerUrl: model.keepServerUrl,
            onRegistered: { model.signIn($0) })
    }

    private func makeViewModelIfNeeded() {
        guard viewModel == nil else { return }
        do {
            viewModel = try Self.makeViewModel(model: model, recoveryKit: recoveryKit)
            errorText = nil
        } catch {
            errorText = ErrorPresenter.message(for: error)
        }
    }
}
