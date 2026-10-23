import GIMFeatures
import SwiftUI

/// The messages of a chat, newest at the bottom. Loads older pages near the top, keeps the visual anchor when they
/// arrive, follows new rows while the bottom is visible and marks messages read.
struct TimelineListView: View {
    let pane: ChatPaneModel

    /// Load older history when the top is this close.
    private nonisolated static let loadOlderDistance: CGFloat = 200
    /// The bottom counts as visible this close to it.
    private nonisolated static let bottomDistance: CGFloat = 40

    private struct ScrollEdges: Equatable {
        var isNearTop: Bool
        var isBottomVisible: Bool
    }

    var body: some View {
        let timeline = pane.timeline
        if timeline.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if timeline.isLoadingOlder {
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityLabel(Text("chat.timeline.loadingOlder", tableName: "Chat"))
                                .padding(.vertical, DesignTokens.spacingS)
                        }
                        ForEach(timeline.items) { item in
                            TimelineRowView(item: item, pane: pane)
                                .id(item.id)
                        }
                    }
                    .padding(.vertical, DesignTokens.spacingS)
                }
                .defaultScrollAnchor(.bottom)
                .onScrollGeometryChange(for: ScrollEdges.self) { geometry in
                    ScrollEdges(
                        isNearTop: geometry.visibleRect.minY < Self.loadOlderDistance,
                        isBottomVisible: geometry.visibleRect.maxY >= geometry.contentSize.height - Self.bottomDistance)
                } action: { _, edges in
                    if edges.isNearTop, timeline.hasMore, !timeline.isLoadingOlder {
                        Task { await timeline.loadOlder() }
                    }
                    pane.isBottomVisible = edges.isBottomVisible
                    Task { await pane.markReadIfNeeded() }
                }
                .onChange(of: pane.search.currentMatchId) { _, matchId in
                    guard let matchId else { return }
                    withAnimation { proxy.scrollTo(TimelineDisplayItem.id(forMessage: matchId), anchor: .center) }
                }
                .onChange(of: timeline.items) { oldItems, newItems in
                    keepPosition(change: timeline.lastChange, oldItems: oldItems, newItems: newItems, proxy: proxy)
                }
                .overlay(alignment: .bottomTrailing) {
                    if !pane.isBottomVisible, let lastId = timeline.items.last?.id {
                        Button {
                            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("chat.timeline.scrollToBottom", tableName: "Chat"))
                        .padding(DesignTokens.spacingM)
                    }
                }
            }
            .alert(
                Text("chat.timeline.delete.title", tableName: "Chat"),
                isPresented: Binding(
                    get: { pane.actions.pendingDelete != nil },
                    set: { if !$0 { pane.cancelDelete() } })
            ) {
                Button(role: .destructive) {
                    pane.confirmDelete()
                } label: {
                    Text("chat.timeline.delete.confirm", tableName: "Chat")
                }
                Button(role: .cancel) {
                    pane.cancelDelete()
                } label: {
                    Text("chat.timeline.delete.cancel", tableName: "Chat")
                }
            } message: {
                Text("chat.timeline.delete.message", tableName: "Chat")
            }
        }
    }

    /// On a prepend, puts the first message shown before it back at the top without animation; when rows were added
    /// at the bottom while it was visible, follows them.
    private func keepPosition(
        change: TimelineChangeSet, oldItems: [TimelineDisplayItem], newItems: [TimelineDisplayItem],
        proxy: ScrollViewProxy
    ) {
        if change.isPrepend {
            guard let anchorId = oldItems.first(where: { $0.messageRow != nil })?.id else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                proxy.scrollTo(anchorId, anchor: .top)
            }
        } else if !change.isReset, pane.isBottomVisible, let lastId = newItems.last?.id,
            change.insertedIds.contains(lastId)
        {
            withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
        }
        Task { await pane.markReadIfNeeded() }
    }
}
