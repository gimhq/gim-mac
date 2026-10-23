import SwiftUI

/// "Sign out…" under the Settings sections: confirms, signs out and shows a failure in a second alert.
struct SignOutButton: View {
    let model: AppModel

    @State private var confirmsSignOut = false
    @State private var failureMessage: String?

    var body: some View {
        Button(role: .destructive) {
            confirmsSignOut = true
        } label: {
            Text("settings.signOut.button", tableName: "Settings")
                .frame(maxWidth: .infinity)
        }
        .disabled(model.phase != .ready)
        .alert(Text("settings.signOut.title", tableName: "Settings"), isPresented: $confirmsSignOut) {
            Button(role: .destructive) {
                Task { failureMessage = await model.signOut() }
            } label: {
                Text("settings.signOut.confirm", tableName: "Settings")
            }
            Button(role: .cancel) {
            } label: {
                Text("settings.signOut.cancel", tableName: "Settings")
            }
        } message: {
            Text("settings.signOut.body", tableName: "Settings")
        }
        .alert(
            Text("settings.signOut.wipeFailed", tableName: "Settings"),
            isPresented: Binding(get: { failureMessage != nil }, set: { if !$0 { failureMessage = nil } })
        ) {
            Button(role: .cancel) {
            } label: {
                Text("settings.signOut.ok", tableName: "Settings")
            }
        } message: {
            Text(failureMessage ?? "")
        }
    }
}
