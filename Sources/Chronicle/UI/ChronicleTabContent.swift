import SwiftUI
import SwiftData

/// Thin wrapper that resolves the `since` date and passes it to the query view.
@available(iOS 17, macOS 14, *)
public struct ChronicleTabContent: View {
    var model: ChronicleViewerModel
    @Binding var showClearConfirmation: Bool
    let currentRunOnly: Bool

    public init(model: ChronicleViewerModel, showClearConfirmation: Binding<Bool>, currentRunOnly: Bool) {
        self.model = model
        self._showClearConfirmation = showClearConfirmation
        self.currentRunOnly = currentRunOnly
    }

    public var body: some View {
        ChronicleQueryContent(
            model: model,
            showClearConfirmation: $showClearConfirmation,
            currentRunOnly: currentRunOnly,
            since: currentRunOnly ? Chronicle.instance.launchDate : nil
        )
        .modelContainer(model.modelContainer)
        .onAppear { model.showCurrentRunOnly = currentRunOnly }
    }
}

// MARK: - Query-owning inner view

/// Owns @Query properties with a dynamic since-date predicate.
/// SwiftData updates these automatically whenever the store changes.
@available(iOS 17, macOS 14, *)
private struct ChronicleQueryContent: View {
    var model: ChronicleViewerModel
    @Binding var showClearConfirmation: Bool
    let currentRunOnly: Bool

    @Query private var events: [PersistedEvent]
    @Query private var networkLogs: [PersistedNetworkLog]
    @Query private var flowEvents: [PersistedFlowEvent]
    @Query private var errorLogs: [PersistedErrorLog]
    @Query private var cloudKitLogs: [PersistedCloudKitLog]
    @Query private var genericEntries: [PersistedGenericEntry]

    init(model: ChronicleViewerModel, showClearConfirmation: Binding<Bool>, currentRunOnly: Bool, since: Date?) {
        self.model = model
        self._showClearConfirmation = showClearConfirmation
        self.currentRunOnly = currentRunOnly
        if let since {
            _events = Query(filter: #Predicate { $0.timestamp >= since }, sort: [SortDescriptor(\.timestamp)])
            _networkLogs = Query(filter: #Predicate { $0.timestamp >= since }, sort: [SortDescriptor(\.timestamp)])
            _flowEvents = Query(filter: #Predicate { $0.timestamp >= since }, sort: [SortDescriptor(\.timestamp)])
            _errorLogs = Query(filter: #Predicate { $0.timestamp >= since }, sort: [SortDescriptor(\.timestamp)])
            _cloudKitLogs = Query(filter: #Predicate { $0.timestamp >= since }, sort: [SortDescriptor(\.timestamp)])
            _genericEntries = Query(filter: #Predicate { $0.timestamp >= since }, sort: [SortDescriptor(\.timestamp)])
        } else {
            _events = Query(sort: [SortDescriptor(\.timestamp)])
            _networkLogs = Query(sort: [SortDescriptor(\.timestamp)])
            _flowEvents = Query(sort: [SortDescriptor(\.timestamp)])
            _errorLogs = Query(sort: [SortDescriptor(\.timestamp)])
            _cloudKitLogs = Query(sort: [SortDescriptor(\.timestamp)])
            _genericEntries = Query(sort: [SortDescriptor(\.timestamp)])
        }
    }

    /// All entries from the store for the current time range, sorted newest first.
    private var allEntries: [any ChronicleEntry] {
        var results: [any ChronicleEntry] = []
        results += events.map { $0.toEvent() }
        results += networkLogs.map { $0.toNetworkLog() }
        results += flowEvents.map { $0.toFlowEvent() }
        results += errorLogs.map { $0.toErrorLog() }
        results += cloudKitLogs.map { $0.toCloudKitLog() }
        results += genericEntries.map { $0.toGenericEntry() }
        return results.sorted { $0.timestamp > $1.timestamp }
    }

    /// Entries after applying category and search filters.
    private var filteredEntries: [any ChronicleEntry] {
        var entries = allEntries
        if !model.selectedCategories.isEmpty {
            entries = entries.filter { model.selectedCategories.contains($0.category) }
        }
        if !model.searchText.isEmpty {
            entries = entries.filter { $0.matches(filter: model.searchText) }
        }
        return entries
    }

	public var filterBar: some View {
		VStack(spacing: 0) {
			 ChronicleFilterBar(model: model, entries: filteredEntries)
			 Divider()
		}
	}
	
	var backgroundColor: Color {
		#if os(macOS)
		Color(nsColor: NSColor.windowBackgroundColor)
		#else
		Color(uiColor: UIColor.systemBackground)
		#endif
	}
	
    public var body: some View {
        NavigationStack {
            VStack {
                if filteredEntries.isEmpty { emptyState } else { entryList }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
					filterBar
						.background(backgroundColor)
            }
            .toolbar {
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
                }
            } message: {
                Text(currentRunOnly
                     ? "This will permanently delete entries from this session."
                     : "This will permanently delete all Chronicle entries.")
            }
        }
    }

    private var entryList: some View {
        List(filteredEntries, id: \.id) { entry in
            if let log = entry as? NetworkLog {
                NavigationLink(destination: NetworkLogDetailScreen(log: log)) { EntryRow(entry: entry) }
            } else if let error = entry as? ErrorLog {
                NavigationLink(destination: ErrorLogDetailScreen(error: error)) { EntryRow(entry: entry) }
            } else if let detailView = entry.category.style.detailView {
                NavigationLink(destination: detailView(entry)) { EntryRow(entry: entry) }
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
            Text(currentRunOnly
                 ? "No entries recorded this session. Try switching to All History."
                 : "No entries match the current filters.")
        }
        .frame(maxHeight: .infinity)
    }
}
