import Foundation
import SwiftData

/// SwiftData-backed storage provider for Chronicle entries.
public final class SwiftDataStorage: @unchecked Sendable {
	private let modelContainer: ModelContainer
	private let modelContext: ModelContext
	
	/// Creates a SwiftDataStorage with the given container.
	/// If no container is provided, creates a default one.
	public init(modelContainer: ModelContainer? = nil) throws {
		if let container = modelContainer {
			self.modelContainer = container
		} else {
			let schema = Schema([
				PersistedEvent.self,
				PersistedNetworkLog.self,
				PersistedFlowEvent.self,
				PersistedErrorLog.self
			])
			
			let dir = URL.cachesDirectory.appendingPathComponent("com.chronicle.history")
			try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
			let url = dir.appendingPathComponent("history.db")
			let config = ModelConfiguration(url: url)
			self.modelContainer = try ModelContainer(for: schema, configurations: [config])
		}
		self.modelContext = ModelContext(self.modelContainer)
		self.modelContext.autosaveEnabled = true
	}
	
	/// Creates an in-memory SwiftDataStorage, useful for testing.
	public static func inMemory() throws -> SwiftDataStorage {
		let schema = Schema([
			PersistedEvent.self,
			PersistedNetworkLog.self,
			PersistedFlowEvent.self,
			PersistedErrorLog.self
		])
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		let container = try ModelContainer(for: schema, configurations: [config])
		return try SwiftDataStorage(modelContainer: container)
	}
	
	/// The SwiftData model container used by this storage.
	public var container: ModelContainer { modelContainer }
	
	// MARK: - Store
	
	/// Stores a Chronicle entry.
	public func store(_ entry: any ChronicleEntry) {
		switch entry {
		case let event as Event:
			modelContext.insert(PersistedEvent.from(event))
		case let networkLog as NetworkLog:
			modelContext.insert(PersistedNetworkLog.from(networkLog))
		case let flowEvent as FlowEvent:
			modelContext.insert(PersistedFlowEvent.from(flowEvent))
		case let errorLog as ErrorLog:
			modelContext.insert(PersistedErrorLog.from(errorLog))
		default:
			break
		}
		try? modelContext.save()
	}
	
	// MARK: - Query
	
	/// Returns all entries matching the given query.
	public func entries(matching query: StorageQuery) -> [any ChronicleEntry] {
		var results: [any ChronicleEntry] = []
		let categories = query.categories ?? Set(EntryCategory.allCases)
		
		if categories.contains(.event) {
			results.append(contentsOf: fetchEvents(matching: query))
		}
		if categories.contains(.network) {
			results.append(contentsOf: fetchNetworkLogs(matching: query))
		}
		if categories.contains(.flow) {
			results.append(contentsOf: fetchFlowEvents(matching: query))
		}
		if categories.contains(.error) {
			results.append(contentsOf: fetchErrorLogs(matching: query))
		}
		
		results.sort { $0.timestamp < $1.timestamp }
		
		if let limit = query.limit {
			return Array(results.suffix(limit))
		}
		return results
	}
	
	/// Returns all stored entries.
	public func allEntries() -> [any ChronicleEntry] {
		entries(matching: .all)
	}
	
	// MARK: - Clear
	
	/// Removes all stored entries.
	public func clear() {
		do {
			try modelContext.delete(model: PersistedEvent.self)
			try modelContext.delete(model: PersistedNetworkLog.self)
			try modelContext.delete(model: PersistedFlowEvent.self)
			try modelContext.delete(model: PersistedErrorLog.self)
			try modelContext.save()
		} catch {
			// Silently handle deletion errors
		}
	}
	
	/// Removes entries older than the given date.
	public func clear(before date: Date) {
		do {
			let eventPredicate = #Predicate<PersistedEvent> { $0.timestamp < date }
			try modelContext.delete(model: PersistedEvent.self, where: eventPredicate)
			
			let networkPredicate = #Predicate<PersistedNetworkLog> { $0.timestamp < date }
			try modelContext.delete(model: PersistedNetworkLog.self, where: networkPredicate)
			
			let flowPredicate = #Predicate<PersistedFlowEvent> { $0.timestamp < date }
			try modelContext.delete(model: PersistedFlowEvent.self, where: flowPredicate)
			
			let errorPredicate = #Predicate<PersistedErrorLog> { $0.timestamp < date }
			try modelContext.delete(model: PersistedErrorLog.self, where: errorPredicate)
			
			try modelContext.save()
		} catch {
			// Silently handle deletion errors
		}
	}
	
	// MARK: - Private Fetch Helpers
	
	private func fetchEvents(matching query: StorageQuery) -> [Event] {
		var descriptor = FetchDescriptor<PersistedEvent>(
			sortBy: [SortDescriptor(\.timestamp)]
		)
		
		if let since = query.since, let until = query.until {
			descriptor.predicate = #Predicate<PersistedEvent> {
				$0.timestamp >= since && $0.timestamp <= until
			}
		} else if let since = query.since {
			descriptor.predicate = #Predicate<PersistedEvent> {
				$0.timestamp >= since
			}
		} else if let until = query.until {
			descriptor.predicate = #Predicate<PersistedEvent> {
				$0.timestamp <= until
			}
		}
		
		let persisted = (try? modelContext.fetch(descriptor)) ?? []
		var events = persisted.map { $0.toEvent() }
		
		if let nameFilter = query.nameContains {
			events = events.filter { $0.name.localizedCaseInsensitiveContains(nameFilter) }
		}
		
		return events
	}
	
	private func fetchNetworkLogs(matching query: StorageQuery) -> [NetworkLog] {
		var descriptor = FetchDescriptor<PersistedNetworkLog>(
			sortBy: [SortDescriptor(\.timestamp)]
		)
		
		if let since = query.since, let until = query.until {
			descriptor.predicate = #Predicate<PersistedNetworkLog> {
				$0.timestamp >= since && $0.timestamp <= until
			}
		} else if let since = query.since {
			descriptor.predicate = #Predicate<PersistedNetworkLog> {
				$0.timestamp >= since
			}
		} else if let until = query.until {
			descriptor.predicate = #Predicate<PersistedNetworkLog> {
				$0.timestamp <= until
			}
		}
		
		let persisted = (try? modelContext.fetch(descriptor)) ?? []
		return persisted.map { $0.toNetworkLog() }
	}
	
	private func fetchFlowEvents(matching query: StorageQuery) -> [FlowEvent] {
		var descriptor = FetchDescriptor<PersistedFlowEvent>(
			sortBy: [SortDescriptor(\.timestamp)]
		)
		
		if let since = query.since, let until = query.until {
			descriptor.predicate = #Predicate<PersistedFlowEvent> {
				$0.timestamp >= since && $0.timestamp <= until
			}
		} else if let since = query.since {
			descriptor.predicate = #Predicate<PersistedFlowEvent> {
				$0.timestamp >= since
			}
		} else if let until = query.until {
			descriptor.predicate = #Predicate<PersistedFlowEvent> {
				$0.timestamp <= until
			}
		}
		
		let persisted = (try? modelContext.fetch(descriptor)) ?? []
		var flowEvents = persisted.map { $0.toFlowEvent() }
		
		if let nameFilter = query.nameContains {
			flowEvents = flowEvents.filter { $0.to.screenName.localizedCaseInsensitiveContains(nameFilter) }
		}
		
		return flowEvents
	}
	
	private func fetchErrorLogs(matching query: StorageQuery) -> [ErrorLog] {
		var descriptor = FetchDescriptor<PersistedErrorLog>(
			sortBy: [SortDescriptor(\.timestamp)]
		)
		
		if let since = query.since, let until = query.until {
			descriptor.predicate = #Predicate<PersistedErrorLog> {
				$0.timestamp >= since && $0.timestamp <= until
			}
		} else if let since = query.since {
			descriptor.predicate = #Predicate<PersistedErrorLog> {
				$0.timestamp >= since
			}
		} else if let until = query.until {
			descriptor.predicate = #Predicate<PersistedErrorLog> {
				$0.timestamp <= until
			}
		}
		
		let persisted = (try? modelContext.fetch(descriptor)) ?? []
		var errorLogs = persisted.map { $0.toErrorLog() }
		
		if let nameFilter = query.nameContains {
			errorLogs = errorLogs.filter {
				$0.message.localizedCaseInsensitiveContains(nameFilter) ||
				$0.domain.localizedCaseInsensitiveContains(nameFilter) ||
				$0.errorType.localizedCaseInsensitiveContains(nameFilter)
			}
		}
		
		return errorLogs
	}
}
