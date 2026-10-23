import GIMFeatures
import SwiftUI

/// The onboarding start: link to a device the user already has first, create and restore as secondary actions, and
/// the server address behind a disclosure.
struct OnboardingStartView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showsServer = false

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("onboarding.welcome.title", tableName: "Onboarding")
                    .font(.title.bold())
                Text("onboarding.start.body", tableName: "Onboarding")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if viewModel.showsLocalStateResetNotice {
                localStateResetNotice
            }
            VStack(spacing: 12) {
                Button {
                    choose(.linkDevice)
                } label: {
                    Text("onboarding.start.link", tableName: "Onboarding")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                HStack(spacing: 12) {
                    Button {
                        choose(.createIdentity)
                    } label: {
                        Text("onboarding.start.create", tableName: "Onboarding")
                            .frame(maxWidth: .infinity)
                    }
                    Button {
                        choose(.restore)
                    } label: {
                        Text("onboarding.start.restore", tableName: "Onboarding")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
            }
            VStack(alignment: .leading, spacing: 6) {
                DisclosureGroup(isExpanded: $showsServer) {
                    ServerField(viewModel: viewModel)
                        .padding(.top, 6)
                } label: {
                    Text("onboarding.server.useAnother", tableName: "Onboarding")
                }
                Text(
                    String(
                        localized: "onboarding.server.current",
                        defaultValue: "Server: \(OnboardingValidation.normalizedServerUrl(viewModel.serverUrl))",
                        table: "Onboarding")
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(24)
    }

    private var localStateResetNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("onboarding.start.localStateReset", tableName: "Onboarding")
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                viewModel.dismissLocalStateResetNotice()
            } label: {
                Text("onboarding.start.dismiss", tableName: "Onboarding")
            }
        }
        .padding(12)
        .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    /// Routes through the view model; when it refused because the server address is invalid, shows the field so the
    /// error is visible.
    private func choose(_ route: OnboardingRoute) {
        viewModel.choose(route)
        if viewModel.path.isEmpty && viewModel.showsAllErrors {
            showsServer = true
        }
    }
}
