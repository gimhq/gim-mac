import Foundation
import GIMClientKit
import GIMFeatures
import Observation

/// The chat list of one main window: `ChatListViewModel` rows as `SidebarRowModel`s plus the selection, which the
/// sidebar list binds to and the shell commands move.
@MainActor
@Observable
final class SidebarModel {
    var selectedChatId: String?
    /// The sidebar's search text; `rows` only lists chats matching it.
    var searchText = ""

    private let list: ChatListViewModel

    init(client: any GimClientAPI) {
        list = ChatListViewModel(client: client)
    }

    var rows: [SidebarRowModel] {
        list.rows.map { SidebarRowModel(row: $0, subtitle: list.subtitle(for: $0)) }
            .filter { ChatListFilter.matches(title: $0.title, subtitle: $0.subtitle, query: searchText) }
    }

    var isLoading: Bool { list.isLoading }
    var errorMessage: String? { list.errorMessage }
    var connectionState: ConnectionState { list.connectionState }

    func start() {
        list.start()
    }

    func stop() {
        list.stop()
    }

    func title(for chatId: String) -> String? {
        list.rows.first { $0.id == chatId }?.title
    }

    /// Selects the row at `index` (Cmd+1 … Cmd+9); out-of-range indices are ignored.
    func select(index: Int) {
        let rows = rows
        guard rows.indices.contains(index) else { return }
        selectedChatId = rows[index].id
    }

    /// Moves the selection down one row; stays on the last row. Selects the first row when nothing is selected.
    func selectNext() {
        move(by: 1)
    }

    /// Moves the selection up one row; stays on the first row. Selects the first row when nothing is selected.
    func selectPrevious() {
        move(by: -1)
    }

    private func move(by offset: Int) {
        guard let current = selectedIndex else {
            select(index: 0)
            return
        }
        select(index: current + offset)
    }

    private var selectedIndex: Int? {
        guard let selectedChatId else { return nil }
        return rows.firstIndex { $0.id == selectedChatId }
    }
}

extension SidebarModel: Hashable {
    nonisolated static func == (lhs: SidebarModel, rhs: SidebarModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
