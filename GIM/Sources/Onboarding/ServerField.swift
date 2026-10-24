import GIMFeatures
import SwiftUI

/// The server address field with its help text and inline error; shared by the start and create-account screens.
struct ServerField: View {
    @Bindable var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(
                text: $viewModel.serverUrl,
                prompt: Text("onboarding.server.placeholder", tableName: "Onboarding")
            ) {
                Text("onboarding.server.label", tableName: "Onboarding")
            }
            .textContentType(.URL)
            .autocorrectionDisabled()
            Text("onboarding.server.help", tableName: "Onboarding")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let kind = viewModel.serverUrlErrorKind {
                Text(OnboardingErrorText.serverUrl(kind))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
