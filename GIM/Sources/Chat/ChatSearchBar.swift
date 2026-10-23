import SwiftUI

/// Find in chat, under the pane header: the query field, the match count, previous/next and close.
struct ChatSearchBar: View {
    let pane: ChatPaneModel
    @FocusState private var isFocused: Bool

    var body: some View {
        let search = pane.search
        HStack(spacing: DesignTokens.spacingS) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(text: Bindable(search).query, prompt: Text("chat.search.placeholder", tableName: "Chat")) {
                Text("chat.search.placeholder", tableName: "Chat")
            }
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onSubmit { pane.findNext() }
            .onKeyPress(.return, phases: .down) { press in
                guard press.modifiers.contains(.shift) else { return .ignored }
                pane.findPrevious()
                return .handled
            }
            .onExitCommand { pane.closeSearch() }
            if let countText = search.countText {
                Text(countText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Button {
                pane.findPrevious()
            } label: {
                Image(systemName: "chevron.up")
            }
            .help(Text("chat.search.previous", tableName: "Chat"))
            .accessibilityLabel(Text("chat.search.previous", tableName: "Chat"))
            .disabled(search.matchIds.isEmpty)
            Button {
                pane.findNext()
            } label: {
                Image(systemName: "chevron.down")
            }
            .help(Text("chat.search.next", tableName: "Chat"))
            .accessibilityLabel(Text("chat.search.next", tableName: "Chat"))
            .disabled(search.matchIds.isEmpty)
            Button {
                pane.closeSearch()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .help(Text("chat.search.close", tableName: "Chat"))
            .accessibilityLabel(Text("chat.search.close", tableName: "Chat"))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignTokens.spacingM)
        .padding(.vertical, DesignTokens.spacingXS)
        .background(.bar)
        .onAppear { isFocused = true }
        .onChange(of: pane.searchFocusRequest) {
            isFocused = true
        }
    }
}
