import Foundation
import SwiftData

// MARK: - Private Fetch Helpers

@available(iOS 17, macOS 14, *)
extension SwiftDataStorage {
    func fetchEvents(matching query: StorageQuery) -> [Event] {
        var descriptor = FetchDescriptor<PersistedEvent>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toEvent() }
    }

    func fetchNetworkLogs(matching query: StorageQuery) -> [NetworkLog] {
        var descriptor = FetchDescriptor<PersistedNetworkLog>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toNetworkLog() }
    }

    func fetchFlowEvents(matching query: StorageQuery) -> [FlowEvent] {
        var descriptor = FetchDescriptor<PersistedFlowEvent>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toFlowEvent() }
    }

    func fetchErrorLogs(matching query: StorageQuery) -> [ErrorLog] {
        var descriptor = FetchDescriptor<PersistedErrorLog>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        return ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toErrorLog() }
    }

    func fetchCloudKitLogs(matching query: StorageQuery, categories: Set<EntryCategory>?) -> [CloudKitLog] {
        var descriptor = FetchDescriptor<PersistedCloudKitLog>(sortBy: [SortDescriptor(\.timestamp)])
        applyDatePredicate(to: &descriptor, query: query)
        let logs = ((try? modelContext.fetch(descriptor)) ?? []).map { $0.toCloudKitLog() }
        if let categories {
            return logs.filter { categories.contains($0.category) }
        }
        return logs
    }

    func fetchGenericEntries(matching query: StorageQuery, categories: Set<EntryCategory>?) -> [GenericChronicleEntry] {
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
    func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedEvent>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedEvent> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedEvent> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedEvent> { $0.timestamp <= until }
        }
    }

    func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedNetworkLog>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedNetworkLog> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedNetworkLog> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedNetworkLog> { $0.timestamp <= until }
        }
    }

    func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedFlowEvent>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedFlowEvent> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedFlowEvent> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedFlowEvent> { $0.timestamp <= until }
        }
    }

    func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedErrorLog>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedErrorLog> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedErrorLog> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedErrorLog> { $0.timestamp <= until }
        }
    }

    func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedCloudKitLog>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedCloudKitLog> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedCloudKitLog> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedCloudKitLog> { $0.timestamp <= until }
        }
    }

    func applyDatePredicate(to descriptor: inout FetchDescriptor<PersistedGenericEntry>, query: StorageQuery) {
        if let since = query.since, let until = query.until {
            descriptor.predicate = #Predicate<PersistedGenericEntry> { $0.timestamp >= since && $0.timestamp <= until }
        } else if let since = query.since {
            descriptor.predicate = #Predicate<PersistedGenericEntry> { $0.timestamp >= since }
        } else if let until = query.until {
            descriptor.predicate = #Predicate<PersistedGenericEntry> { $0.timestamp <= until }
        }
    }
}
