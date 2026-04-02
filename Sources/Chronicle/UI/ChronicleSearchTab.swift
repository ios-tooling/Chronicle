import SwiftUI
import SwiftData

/// A searchable Chronicle view that queries all history.
@available(iOS 17, macOS 14, *)
public struct ChronicleSearchTab: View {
	@Bindable var model: ChronicleViewerModel
	@Binding var showClearConfirmation: Bool
	
	public init(model: ChronicleViewerModel, showClearConfirmation: Binding<Bool>) {
		self.model = model
		self._showClearConfirmation = showClearConfirmation
	}
	
	public var body: some View {
		ChronicleSearchContent(model: model, showClearConfirmation: $showClearConfirmation)
			.modelContainer(model.modelContainer)
			.searchable(text: $model.searchText, prompt: "Search entries")
	}
}

@available(iOS 17, macOS 14, *)
private struct ChronicleSearchContent: View {
	var model: ChronicleViewerModel
	@Binding var showClearConfirmation: Bool
	
	@Query(sort: [SortDescriptor(\PersistedEvent.timestamp)]) private var events: [PersistedEvent]
	@Query(sort: [SortDescriptor(\PersistedNetworkLog.timestamp)]) private var networkLogs: [PersistedNetworkLog]
	@Query(sort: [SortDescriptor(\PersistedFlowEvent.timestamp)]) private var flowEvents: [PersistedFlowEvent]
	@Query(sort: [SortDescriptor(\PersistedErrorLog.timestamp)]) private var errorLogs: [PersistedErrorLog]
	@Query(sort: [SortDescriptor(\PersistedCloudKitLog.timestamp)]) private var cloudKitLogs: [PersistedCloudKitLog]
	@Query(sort: [SortDescriptor(\PersistedGenericEntry.timestamp)]) private var genericEntries: [PersistedGenericEntry]
	
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
	
	private var filteredEntries: [any ChronicleEntry] {
		var entries = allEntries
		if !model.selectedCategories.isEmpty {
			entries = entries.filter { model.selectedCategories.contains($0.category) }
		}
		if !model.selectedTags.isEmpty {
			entries = entries.filter { entry in
				guard let tags = entry.tags else { return false }
				return model.selectedTags.isSubset(of: tags)
			}
		}
		if !model.searchText.isEmpty {
			entries = entries.filter { $0.matches(filter: model.searchText) }
		}
		return entries
	}
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				filterBar
				if filteredEntries.isEmpty { emptyState } else { entryList }
			}
		}
	}
	
	private var filterBar: some View {
		VStack(spacing: 2) {
			ChronicleFilterBar(model: model, entries: allEntries)
			Divider()
		}
		.frame(maxWidth: .infinity)
		.background(backgroundColor)
	}
	
	private var entryList: some View {
		ChronicleEntryList(entries: filteredEntries)
			.environment(\.showTags, model.showTags)
			.environment(\.tagTapAction, model.toggleTag)
	}
	
	private var emptyState: some View {
		ContentUnavailableView {
			Label("No Results", systemImage: "magnifyingglass")
		} description: {
			if model.searchText.isEmpty {
				Text("Enter a search term to find entries.")
			} else {
				Text("No entries match \"\(model.searchText)\".")
			}
		}
		.frame(maxHeight: .infinity)
	}
	
	private var backgroundColor: Color {
		#if os(macOS)
				Color(nsColor: NSColor.windowBackgroundColor)
		#else
				Color(uiColor: UIColor.systemBackground)
		#endif
	}
}
