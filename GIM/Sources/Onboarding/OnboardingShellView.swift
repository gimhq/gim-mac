import GIMFeatures
import SwiftUI

/// Onboarding below the app model: the intro pages, then the start screen with the create, link and restore routes,
/// then the steps after a new identity was created.
struct OnboardingShellView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var introDone = false
    /// The new user's ID for the recovery kit; read from the client when the kit step starts.
    @State private var kitUserId: String?

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

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
            OnboardingRoutePlaceholderView()
        }
    }

    @ViewBuilder
    private func stageView(_ stage: IdentityStage) -> some View {
        switch stage {
        case .recoveryCode(let recoveryCode):
            if let kitUserId {
                RecoveryKitView(viewModel: recoveryCode, userId: kitUserId)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task { kitUserId = (try? await viewModel.context?.client().userId()) ?? "" }
            }
        case .claimHandle(let claimHandle):
            ClaimHandleView(viewModel: claimHandle)
        }
    }
}

/// Stands in for the restore screen until it exists.
struct OnboardingRoutePlaceholderView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
