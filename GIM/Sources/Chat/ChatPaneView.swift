import SwiftUI

/// Placeholder chat pane. Replaced by the chat workstream.
struct ChatPaneView: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text("chat.placeholder.comingSoon", tableName: "Chat")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
