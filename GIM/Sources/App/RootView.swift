import SwiftUI

/// The main window's content, routed by `AppModel.phase`.
struct RootView: View {
    let model: AppModel

    var body: some View {
        Group {
            switch model.phase {
            case .launching:
                launching
            case .onboarding:
                OnboardingFlow(model: model)
            case .ready:
                // Replaced by the sidebar layout in a later subtask.
                Text(
                    String(
                        localized: "app.ready.placeholder",
                        defaultValue: "Signed in as \(model.session?.displayName ?? "")", table: "App"))
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .task { await model.start() }
    }

    private var launching: some View {
        VStack(spacing: 12) {
            if let error = model.launchError {
                Text(error)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await model.start() }
                } label: {
                    Text("app.launch.tryAgain", tableName: "App")
                }
            } else {
                ProgressView()
                Text("app.launch.loading", tableName: "App")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
