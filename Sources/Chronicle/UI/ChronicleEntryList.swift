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
			} else if let ck = entry as? CloudKitLog, hasCachedRecord(for: ck.id) {
				NavigationLink(destination: CKRecordDetailScreen(entryID: ck.id, log: ck)) { EntryRow(entry: entry) }
			} else if let detailView = entry.category.style.detailView {
				NavigationLink(destination: detailView(entry)) { EntryRow(entry: entry) }
			} else {
				EntryRow(entry: entry)
			}
		}
		.listStyle(.plain)
	}

	private func hasCachedRecord(for entryID: UUID) -> Bool {
		Chronicle.instance.cloudKit.recordCache?.hasRecord(for: entryID) ?? false
	}
}
