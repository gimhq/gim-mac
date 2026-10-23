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
                MainWindowView(model: model)
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
