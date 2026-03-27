import SwiftUI

/// The content view for a single Chronicle tab.
@available(iOS 17, macOS 14, *)
public struct ChronicleTabContent: View {
    @Bindable var model: ChronicleViewerModel
    @Binding var showClearConfirmation: Bool
    let currentRunOnly: Bool

    public init(model: ChronicleViewerModel, showClearConfirmation: Binding<Bool>, currentRunOnly: Bool) {
        self.model = model
        self._showClearConfirmation = showClearConfirmation
        self.currentRunOnly = currentRunOnly
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ChronicleFilterBar(model: model)
                Divider()
                if model.entries.isEmpty { emptyState } else { entryList }
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
                Button(currentRunOnly ? "Clear Current Run" : "Clear All", role: .destructive) {
                    if currentRunOnly, let launchDate = Chronicle.instance.launchDate {
                        Chronicle.instance.clear(since: launchDate)
                    } else {
                        Chronicle.instance.clear()
                    }
                    model.refresh()
                }
            } message: {
                Text(currentRunOnly
                     ? "This will permanently delete entries from this session."
                     : "This will permanently delete all Chronicle entries.")
            }
            .onAppear {
                model.showCurrentRunOnly = currentRunOnly
                model.refresh()
            }
        }
    }

    private var entryList: some View {
        List(model.entries, id: \.id) { entry in
            if let log = entry as? NetworkLog {
                NavigationLink(destination: NetworkLogDetailScreen(log: log)) {
                    EntryRow(entry: entry)
                }
            } else if let error = entry as? ErrorLog {
                NavigationLink(destination: ErrorLogDetailScreen(error: error)) {
                    EntryRow(entry: entry)
                }
            } else if let detailView = entry.category.style.detailView {
                NavigationLink(destination: detailView(entry)) {
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
            if currentRunOnly {
                Text("No entries recorded this session. Try switching to All History.")
            } else {
                Text("No entries match the current filters.")
            }
        }
        .frame(maxHeight: .infinity)
    }
}
