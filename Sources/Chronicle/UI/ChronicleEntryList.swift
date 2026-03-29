import SwiftUI

@available(iOS 17, macOS 14, *)
public struct ChronicleEntryList: View {
	let entries: [any ChronicleEntry]

	public init(entries: [any ChronicleEntry]) {
		self.entries = entries
	}

	public var body: some View {
		List(entries, id: \.id) { entry in
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
}
