import Foundation

/// Tracks application events and stores them via SwiftData.
public final class EventTracker: Sendable {
    private let storage: SwiftDataStorage

    init(storage: SwiftDataStorage) {
        self.storage = storage
    }

    /// Records a named event with optional metadata.
    public func track(_ name: String, metadata: EventMetadata? = nil) {
        let event = Event(name: name, metadata: metadata)
        storage.store(event)
    }

    /// Returns recent events, up to the specified limit.
    public func recentEvents(limit: Int = 100) -> [Event] {
        let query = StorageQuery(categories: [.event], limit: limit)
        return storage.entries(matching: query).compactMap { $0 as? Event }
    }

    /// Returns all stored events.
    public func allEvents() -> [Event] {
        let query = StorageQuery(categories: [.event])
        return storage.entries(matching: query).compactMap { $0 as? Event }
    }
}
