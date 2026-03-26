import Foundation
import SwiftData

/// SwiftData-backed storage provider for Chronicle entries.
@available(iOS 17, macOS 14, *)
public final class SwiftDataStorage: @unchecked Sendable {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    private static var schema: Schema {
        Schema([
            PersistedEvent.self,
            PersistedNetworkLog.self,
            PersistedFlowEvent.self,
            PersistedErrorLog.self,
            PersistedGenericEntry.self,
        ])
    }

    public init(modelContainer: ModelContainer? = nil) throws {
        if let container = modelContainer {
            self.modelContainer = container
        } else {
            let dir = URL.cachesDirectory.appendingPathComponent("com.chronicle.history")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent("history.db")
            let config = ModelConfiguration(url: url, cloudKitDatabase: .none)
            self.modelContainer = try ModelContainer(for: Self.schema, configurations: [config])
			  print("Chronicle database setup at \(url.path(percentEncoded: false))")
        }
        self.modelContext = ModelContext(self.modelContainer)
        self.modelContext.autosaveEnabled = true
    }

    public static func inMemory() throws -> SwiftDataStorage {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return try SwiftDataStorage(modelContainer: container)
    }

    public var container: ModelContainer { modelContainer }

    // MARK: - Store

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
            if let generic = PersistedGenericEntry.from(entry) {
                modelContext.insert(generic)
            }
        }
        try? modelContext.save()
    }

    // MARK: - Query

    public func entries(matching query: StorageQuery) -> [any ChronicleEntry] {
        var results: [any ChronicleEntry] = []
        let categories = query.categories

        let fetchBuiltIn = categories == nil
        if fetchBuiltIn || categories!.contains(.event) {
            results.append(contentsOf: fetchEvents(matching: query))
        }
        if fetchBuiltIn || categories!.contains(.network) {
            results.append(contentsOf: fetchNetworkLogs(matching: query))
        }
        if fetchBuiltIn || categories!.contains(.flow) {
            results.append(contentsOf: fetchFlowEvents(matching: query))
        }
        if fetchBuiltIn || categories!.contains(.error) {
            results.append(contentsOf: fetchErrorLogs(matching: query))
        }

        // Always fetch generic entries (custom categories)
        let customCategories = categories?.filter { !EntryCategory.builtIn.contains($0) }
        if categories == nil || customCategories?.isEmpty == false {
            results.append(contentsOf: fetchGenericEntries(matching: query, categories: customCategories))
        }

        results.sort { $0.timestamp < $1.timestamp }

        if let limit = query.limit {
            results = Array(results.suffix(limit))
        }

        if let filter = query.nameContains {
            results = results.filter { $0.matches(filter: filter) }
        }
        return results
    }

    public func allEntries() -> [any ChronicleEntry] {
        entries(matching: .all)
    }

    // MARK: - Clear

    public func clear() {
        do {
            try modelContext.delete(model: PersistedEvent.self)
            try modelContext.delete(model: PersistedNetworkLog.self)
            try modelContext.delete(model: PersistedFlowEvent.self)
            try modelContext.delete(model: PersistedErrorLog.self)
            try modelContext.delete(model: PersistedGenericEntry.self)
            try modelContext.save()
        } catch {}
    }

    public func clear(before date: Date) {
        do {
            try modelContext.delete(model: PersistedEvent.self, where: #Predicate<PersistedEvent> { $0.timestamp < date })
            try modelContext.delete(model: PersistedNetworkLog.self, where: #Predicate<PersistedNetworkLog> { $0.timestamp < date })
            try modelContext.delete(model: PersistedFlowEvent.self, where: #Predicate<PersistedFlowEvent> { $0.timestamp < date })
            try modelContext.delete(model: PersistedErrorLog.self, where: #Predicate<PersistedErrorLog> { $0.timestamp < date })
            try modelContext.delete(model: PersistedGenericEntry.self, where: #Predicate<PersistedGenericEntry> { $0.timestamp < date })
            try modelContext.save()
        } catch {}
    }

    public func clear(since date: Date) {
        do {
            try modelContext.delete(model: PersistedEvent.self, where: #Predicate<PersistedEvent> { $0.timestamp >= date })
            try modelContext.delete(model: PersistedNetworkLog.self, where: #Predicate<PersistedNetworkLog> { $0.timestamp >= date })
            try modelContext.delete(model: PersistedFlowEvent.self, where: #Predicate<PersistedFlowEvent> { $0.timestamp >= date })
            try modelContext.delete(model: PersistedErrorLog.self, where: #Predicate<PersistedErrorLog> { $0.timestamp >= date })
            try modelContext.delete(model: PersistedGenericEntry.self, where: #Predicate<PersistedGenericEntry> { $0.timestamp >= date })
            try modelContext.save()
        } catch {}
    }
}

// MARK: - Private Fetch Helpers

@available(iOS 17, macOS 14, *)
extension SwiftDataStorage {
    private func fetchEvents(matching query: StorageQuery) -> [Event] {
        var descriptor = FetchDescriptor<PersistedEvent>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toEvent() }
    }

    private func fetchNetworkLogs(matching query: StorageQuery) -> [NetworkLog] {
        var descriptor = FetchDescriptor<PersistedNetworkLog>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toNetworkLog() }
    }

    private func fetchFlowEvents(matching query: StorageQuery) -> [FlowEvent] {
        var descriptor = FetchDescriptor<PersistedFlowEvent>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toFlowEvent() }
    }

    private func fetchErrorLogs(matching query: StorageQuery) -> [ErrorLog] {
        var descriptor = FetchDescriptor<PersistedErrorLog>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toErrorLog() }
    }

    private func fetchGenericEntries(matching query: StorageQuery, categories: Set<EntryCategory>?) -> [GenericChronicleEntry] {
        var descriptor = FetchDescriptor<PersistedGenericEntry>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        let persisted = (try? modelContext.fetch(descriptor)) ?? []
        let entries = persisted.map { $0.toGenericEntry() }
        if let categories {
            return entries.filter { categories.contains($0.category) }
        }
        return entries
    }
}

// MARK: - Date Predicate Helpers

@available(iOS 17, macOS 14, *)
extension SwiftDataStorage {
    private func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedEvent>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedEvent> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedEvent> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedEvent> { $0.timestamp <= until }
        }
    }

    private func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedNetworkLog>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedNetworkLog> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedNetworkLog> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedNetworkLog> { $0.timestamp <= until }
        }
    }

    private func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedFlowEvent>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedFlowEvent> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedFlowEvent> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedFlowEvent> { $0.timestamp <= until }
        }
    }

    private func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedErrorLog>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedErrorLog> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedErrorLog> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedErrorLog> { $0.timestamp <= until }
        }
    }

    private func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedGenericEntry>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedGenericEntry> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedGenericEntry> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedGenericEntry> { $0.timestamp <= until }
        }
    }
}
