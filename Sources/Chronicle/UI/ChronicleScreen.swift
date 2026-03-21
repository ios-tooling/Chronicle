import SwiftUI

/// A SwiftUI screen that displays Chronicle entry history with filtering.
public struct ChronicleScreen: View {
    @State private var model = ChronicleViewerModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ChronicleFilterBar(model: model)
                Divider()

                if model.entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle("Chronicle")
            .searchable(text: $model.searchText, prompt: "Filter entries")
            .onSubmit(of: .search) { model.refresh() }
            .onChange(of: model.searchText) {
                if model.searchText.isEmpty { model.refresh() }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button { model.refresh() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear { model.refresh() }
        }
    }

    private var entryList: some View {
        List(model.entries, id: \.id) { entry in
            EntryRow(entry: entry)
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Entries", systemImage: "doc.text.magnifyingglass")
        } description: {
            if model.showCurrentRunOnly {
                Text("No entries recorded this session. Try switching to All History.")
            } else {
                Text("No entries match the current filters.")
            }
        }
    }
}
