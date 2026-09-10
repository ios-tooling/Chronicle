import Foundation
import SwiftData

// MARK: - Attaching errors to logged requests

@available(iOS 17, macOS 14, *)
extension SwiftDataStorage {
	/// Attaches `error` to the network log `reference` points at. Returns false when no such
	/// request has been logged, so the caller can record the error on its own.
	func attach(_ error: ErrorLog, to reference: NetworkLogReference) -> Bool {
		guard let persisted = networkLog(matching: reference) else { return false }
		var linked = error
		linked.linkedNetworkLogID = persisted.entryID
		persisted.linkedErrorJSON = try? JSONEncoder().encode(linked)
		try? modelContext.save()
		return true
	}

	/// The most recent request logged at the reference's start time and URL (query ignored).
	private func networkLog(matching reference: NetworkLogReference) -> PersistedNetworkLog? {
		// Dates round-trip through the store exactly, but a millisecond of slack costs nothing.
		let lower = reference.startedAt.addingTimeInterval(-0.001)
		let upper = reference.startedAt.addingTimeInterval(0.001)
		let descriptor = FetchDescriptor<PersistedNetworkLog>(
			predicate: #Predicate { $0.startTime >= lower && $0.startTime <= upper },
			sortBy: [SortDescriptor<PersistedNetworkLog>(\.timestamp, order: .reverse)]
		)
		let target = reference.url.chronicle_withoutQuery
		let candidates = (try? modelContext.fetch(descriptor)) ?? []
		return candidates.first { URL(string: $0.url)?.chronicle_withoutQuery == target }
	}
}
