import Foundation
import os
import SwiftData

/// SwiftData-backed storage provider for Chronicle entries.
///
/// All `ModelContext` access is serialized via an internal lock,
/// making this class safe to use from any thread.
@available(iOS 17, macOS 14, *)
public final class SwiftDataStorage: @unchecked Sendable {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let contextLock = OSAllocatedUnfairLock()
    public var maxEntries: Int?

    private static var schema: Schema {
        Schema([
            PersistedEvent.self,
            PersistedNetworkLog.self,
            PersistedFlowEvent.self,
            PersistedErrorLog.self,
            PersistedCloudKitLog.self,
            PersistedGenericEntry.self,
        ])
    }

    public init(modelContainer: ModelContainer? = nil, configuration: ChronicleConfiguration) throws {
        if let container = modelContainer {
            self.modelContainer = container
        } else {
            let parent = configuration.databaseLocation ?? URL.cachesDirectory
            let dir = parent.appendingPathComponent("com.chronicle.history")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent("history.db")
            let config = ModelConfiguration(url: url, allowsSave: !configuration.isReadOnly, cloudKitDatabase: .none)
            self.modelContainer = try ModelContainer(for: Self.schema, configurations: [config])
			  print("Chronicle database setup at \(url.path(percentEncoded: false))")
        }
        self.modelContext = ModelContext(self.modelContainer)
        self.modelContext.autosaveEnabled = true
    }

    public static func inMemory() throws -> SwiftDataStorage {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return try SwiftDataStorage(modelContainer: container, configuration: .default)
    }

    public var container: ModelContainer { modelContainer }

    /// Creates a ModelContainer for an existing Chronicle database on disk.
    /// Useful for external viewer apps that read another app's Chronicle data.
    public static func containerForExternalDatabase(at directoryURL: URL) throws -> ModelContainer {
        let dbURL = directoryURL.appendingPathComponent("history.db")
        let config = ModelConfiguration(url: dbURL, allowsSave: false, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - Store

    public func store(_ entry: any ChronicleEntry) {
        contextLock.withLock {
            switch entry {
            case let event as Event:
                modelContext.insert(PersistedEvent.from(event))
            case let networkLog as NetworkLog:
                modelContext.insert(PersistedNetworkLog.from(networkLog))
            case let flowEvent as FlowEvent:
                modelContext.insert(PersistedFlowEvent.from(flowEvent))
            case let errorLog as ErrorLog:
                modelContext.insert(PersistedErrorLog.from(errorLog))
            case let cloudKitLog as CloudKitLog:
                modelContext.insert(PersistedCloudKitLog.from(cloudKitLog))
            default:
                if let generic = PersistedGenericEntry.from(entry) {
                    modelContext.insert(generic)
                }
            }
            if let maxEntries { enforceLimit(maxEntries) }
            try? modelContext.save()
        }
    }

    /// Deletes the oldest entries across all types until the total count is at or below `maxEntries`.
    private func enforceLimit(_ maxEntries: Int) {
        var total = 0
        total += (try? modelContext.fetchCount(FetchDescriptor<PersistedEvent>())) ?? 0
        total += (try? modelContext.fetchCount(FetchDescriptor<PersistedNetworkLog>())) ?? 0
        total += (try? modelContext.fetchCount(FetchDescriptor<PersistedFlowEvent>())) ?? 0
        total += (try? modelContext.fetchCount(FetchDescriptor<PersistedErrorLog>())) ?? 0
        total += (try? modelContext.fetchCount(FetchDescriptor<PersistedCloudKitLog>())) ?? 0
        total += (try? modelContext.fetchCount(FetchDescriptor<PersistedGenericEntry>())) ?? 0

        guard total > maxEntries else { return }
        let excess = total - maxEntries

        var candidates: [(timestamp: Date, model: any PersistentModel)] = []

        func collectOldest<T: PersistentModel>(_ type: T.Type, _ key: KeyPath<T, Date> & Sendable) {
            var descriptor = FetchDescriptor<T>(sortBy: [SortDescriptor(key)])
            descriptor.fetchLimit = excess
            if let results = try? modelContext.fetch(descriptor) {
                candidates += results.map { ($0[keyPath: key], $0) }
            }
        }

        collectOldest(PersistedEvent.self, \.timestamp)
        collectOldest(PersistedNetworkLog.self, \.timestamp)
        collectOldest(PersistedFlowEvent.self, \.timestamp)
        collectOldest(PersistedErrorLog.self, \.timestamp)
        collectOldest(PersistedCloudKitLog.self, \.timestamp)
        collectOldest(PersistedGenericEntry.self, \.timestamp)

        candidates.sort { $0.timestamp < $1.timestamp }
        for candidate in candidates.prefix(excess) {
            modelContext.delete(candidate.model)
        }
    }

    // MARK: - Query

    public func entries(matching query: StorageQuery) -> [any ChronicleEntry] {
        contextLock.withLock {
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
            if fetchBuiltIn || categories!.contains(.cloudKitUpload) || categories!.contains(.cloudKitDownload) || categories!.contains(.cloudKitDelete) {
                results.append(contentsOf: fetchCloudKitLogs(matching: query, categories: categories))
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
    }

    public func allEntries() -> [any ChronicleEntry] {
        entries(matching: .all)
    }

    // MARK: - Clear

    public func clear() {
        contextLock.withLock {
            do {
                try modelContext.delete(model: PersistedEvent.self)
                try modelContext.delete(model: PersistedNetworkLog.self)
                try modelContext.delete(model: PersistedFlowEvent.self)
                try modelContext.delete(model: PersistedErrorLog.self)
                try modelContext.delete(model: PersistedCloudKitLog.self)
                try modelContext.delete(model: PersistedGenericEntry.self)
                try modelContext.save()
            } catch {}
        }
    }

    public func clear(before date: Date) {
        contextLock.withLock {
            do {
                try modelContext.delete(model: PersistedEvent.self, where: #Predicate<PersistedEvent> { $0.timestamp < date })
                try modelContext.delete(model: PersistedNetworkLog.self, where: #Predicate<PersistedNetworkLog> { $0.timestamp < date })
                try modelContext.delete(model: PersistedFlowEvent.self, where: #Predicate<PersistedFlowEvent> { $0.timestamp < date })
                try modelContext.delete(model: PersistedErrorLog.self, where: #Predicate<PersistedErrorLog> { $0.timestamp < date })
                try modelContext.delete(model: PersistedCloudKitLog.self, where: #Predicate<PersistedCloudKitLog> { $0.timestamp < date })
                try modelContext.delete(model: PersistedGenericEntry.self, where: #Predicate<PersistedGenericEntry> { $0.timestamp < date })
                try modelContext.save()
            } catch {}
        }
    }

    public func clear(since date: Date) {
        contextLock.withLock {
            do {
                try modelContext.delete(model: PersistedEvent.self, where: #Predicate<PersistedEvent> { $0.timestamp >= date })
                try modelContext.delete(model: PersistedNetworkLog.self, where: #Predicate<PersistedNetworkLog> { $0.timestamp >= date })
                try modelContext.delete(model: PersistedFlowEvent.self, where: #Predicate<PersistedFlowEvent> { $0.timestamp >= date })
                try modelContext.delete(model: PersistedErrorLog.self, where: #Predicate<PersistedErrorLog> { $0.timestamp >= date })
                try modelContext.delete(model: PersistedCloudKitLog.self, where: #Predicate<PersistedCloudKitLog> { $0.timestamp >= date })
                try modelContext.delete(model: PersistedGenericEntry.self, where: #Predicate<PersistedGenericEntry> { $0.timestamp >= date })
                try modelContext.save()
            } catch {}
        }
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

    private func fetchCloudKitLogs(matching query: StorageQuery, categories: Set<EntryCategory>?) -> [CloudKitLog] {
        var descriptor = FetchDescriptor<PersistedCloudKitLog>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        let logs = ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toCloudKitLog() }
        if let categories {
            return logs.filter { categories.contains($0.category) }
        }
        return logs
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

    private func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedCloudKitLog>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedCloudKitLog> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedCloudKitLog> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedCloudKitLog> { $0.timestamp <= until }
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
