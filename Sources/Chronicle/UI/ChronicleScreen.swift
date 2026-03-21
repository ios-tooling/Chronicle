import SwiftUI

/// A SwiftUI screen that displays Chronicle entry history with filtering.
public struct ChronicleScreen: View {
    @State private var model = ChronicleViewerModel()
    @State private var showClearConfirmation = false

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
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive) { showClearConfirmation = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .confirmationDialog("Clear Entries", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    Chronicle.instance.clear()
                    model.refresh()
                }
            } message: {
                Text("This will permanently delete all Chronicle entries.")
            }
            .onAppear { model.refresh() }
        }
    }

    private var entryList: some View {
        List(model.entries, id: \.id) { entry in
            if let log = entry as? NetworkLog {
                NavigationLink(destination: NetworkLogDetailScreen(log: log)) {
                    EntryRow(entry: entry)
                }
            } else if let error = entry as? ErrorLog, let linkedLog = model.networkLog(for: error.linkedNetworkLogID) {
                NavigationLink(destination: NetworkLogDetailScreen(log: linkedLog)) {
                    EntryRow(entry: entry)
                }
            } else {
                EntryRow(entry: entry)
            }
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
