import GIMFeatures
import SwiftUI

/// Onboarding below the app model: the intro pages, then the start screen with the create, link and restore routes,
/// then the steps after a new identity was created.
struct OnboardingShellView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var introDone = false

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if !introDone {
                OnboardingIntroView { introDone = true }
            } else if viewModel.stage != nil {
                OnboardingStagePlaceholderView()
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
        case .createIdentity, .restore:
            OnboardingRoutePlaceholderView()
        }
    }
}

/// Stands in for the recovery key and username steps until the create-account screens exist.
struct OnboardingStagePlaceholderView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Stands in for the create-account and restore screens until they exist.
struct OnboardingRoutePlaceholderView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
