import Foundation
import os
import SwiftData

/// SwiftData-backed storage provider for Chronicle entries.
///
/// Implemented as a `@ModelActor` so all `ModelContext` access is isolated to
/// the actor's own executor. This keeps the context off the main queue's
/// binding and makes the storage safe to use from any thread.
@available(iOS 17, macOS 14, *)
@ModelActor
public actor SwiftDataStorage {
    var maxEntries: Int?

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

    /// Builds the on-disk container described by `configuration`.
    static func makeContainer(configuration: ChronicleConfiguration) throws -> ModelContainer {
        let parent = configuration.databaseLocation ?? URL.cachesDirectory
        let dir = parent.appendingPathComponent("com.chronicle.history")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("history.db")
        let config = ModelConfiguration(url: url, allowsSave: !configuration.isReadOnly, cloudKitDatabase: .none)
        print("Chronicle database setup at \(url.path(percentEncoded: false))")
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Creates storage backed by the container in `configuration`, or a fresh on-disk one.
    public static func make(configuration: ChronicleConfiguration) throws -> SwiftDataStorage {
        if let container = configuration.modelContainer {
            return SwiftDataStorage(modelContainer: container)
        }
        return SwiftDataStorage(modelContainer: try makeContainer(configuration: configuration))
    }

    public static func inMemory() throws -> SwiftDataStorage {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return SwiftDataStorage(modelContainer: container)
    }

    /// The backing container, for advanced usage (e.g. the viewer UI).
    public nonisolated var container: ModelContainer { modelContainer }

    /// Creates a ModelContainer for an existing Chronicle database on disk.
    /// Useful for external viewer apps that read another app's Chronicle data.
    public static func containerForExternalDatabase(at directoryURL: URL) throws -> ModelContainer {
        let dbURL = directoryURL.appendingPathComponent("history.db")
        let config = ModelConfiguration(url: dbURL, allowsSave: false, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [config])
    }

    public func setMaxEntries(_ value: Int?) {
        maxEntries = value
    }

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
            try modelContext.delete(model: PersistedCloudKitLog.self)
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
            try modelContext.delete(model: PersistedCloudKitLog.self, where: #Predicate<PersistedCloudKitLog> { $0.timestamp < date })
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
            try modelContext.delete(model: PersistedCloudKitLog.self, where: #Predicate<PersistedCloudKitLog> { $0.timestamp >= date })
            try modelContext.delete(model: PersistedGenericEntry.self, where: #Predicate<PersistedGenericEntry> { $0.timestamp >= date })
            try modelContext.save()
        } catch {}
    }
}
