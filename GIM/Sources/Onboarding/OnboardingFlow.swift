import GIMFeatures
import SwiftUI

/// Placeholder onboarding: signs in through the fake client. Replaced by the onboarding workstream.
struct OnboardingFlow: View {
    let model: AppModel
    @State private var isRunning = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("onboarding.welcome.title", tableName: "Onboarding")
                .font(.title)
            Text("onboarding.welcome.body", tableName: "Onboarding")
                .foregroundStyle(.secondary)
            Button {
                startDemo()
            } label: {
                Text("onboarding.demo.start", tableName: "Onboarding")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
            if let errorText {
                Text(errorText)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func startDemo() {
        isRunning = true
        errorText = nil
        Task {
            do {
                try await model.createDemoIdentity(
                    displayName: String(localized: "onboarding.demo.displayName", table: "Onboarding"))
            } catch {
                errorText = ErrorPresenter.message(for: error)
            }
            isRunning = false
        }
    }
}
