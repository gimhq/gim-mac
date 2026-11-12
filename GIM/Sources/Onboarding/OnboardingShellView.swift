import GIMFeatures
import SwiftUI

/// Onboarding below the app model: the intro pages, then the start screen with the create, link and restore routes,
/// then the steps after a new identity was created.
struct OnboardingShellView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var introDone = false

    var body: some View {
        Group {
            if !introDone {
                OnboardingIntroView { introDone = true }
            } else if let stage = viewModel.stage {
                stageView(stage)
            } else {
                NavigationStack(path: $viewModel.path) {
                    OnboardingStartView(viewModel: viewModel)
                        .navigationDestination(for: OnboardingRoute.self) { route in
                            destination(for: route)
                        }
                }
            }
        }
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 520, minHeight: 440)
    }

    @ViewBuilder
    private func destination(for route: OnboardingRoute) -> some View {
        switch route {
        case .linkDevice:
            if let context = viewModel.context {
                LinkDeviceView(context: context, onLeave: { viewModel.path = [] })
            } else {
                OnboardingStartView(viewModel: viewModel)
            }
        case .createIdentity:
            CreateAccountView(viewModel: viewModel)
        case .restore:
            if let context = viewModel.context {
                RestoreView(context: context, onLeave: { viewModel.path = [] })
            } else {
                OnboardingStartView(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func stageView(_ stage: IdentityStage) -> some View {
        switch stage {
        case .recoveryKit(let kit):
            RecoveryKitView(viewModel: kit)
        case .claimHandle(let finish):
            FinishSetupView(viewModel: finish)
        }
    }
}

/// The last create-account step. There are no usernames: GIMFeatures still ends the create flow on its handle step,
/// so this skips it at once and only shows progress, or the error with a retry.
private struct FinishSetupView: View {
    let viewModel: ClaimHandleViewModel

    var body: some View {
        VStack(spacing: 12) {
            if let kind = viewModel.errorKind {
                Text(kind.text)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await viewModel.skip() }
                } label: {
                    Text("onboarding.flow.tryAgain", tableName: "Onboarding")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                ProgressView()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await viewModel.skip() }
    }
}
