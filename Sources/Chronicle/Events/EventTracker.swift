import Foundation
import TagAlong

/// Tracks application events and stores them via SwiftData.
@available(iOS 17, macOS 14, *)
public final class EventTracker: Sendable {
    private let storage: SwiftDataStorage
    private let writer: StorageWriter

    init(storage: SwiftDataStorage, writer: StorageWriter) {
        self.storage = storage
        self.writer = writer
    }

    /// Records a named event with optional context.
    public func track(_ name: String, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let event = Event(name: name, context: context, tags: tags, referenceURL: referenceURL, referenceID: referenceID, sourceFile: (file as NSString).lastPathComponent, sourceFunction: function, sourceLine: line)
        writer.store(event)
    }

    /// Returns recent events, up to the specified limit.
    public func recentEvents(limit: Int = 100) async -> [Event] {
        let query = StorageQuery(categories: [.event], limit: limit)
        return await storage.entries(matching: query).compactMap { $0 as? Event }
    }

    /// Returns all stored events.
    public func allEvents() async -> [Event] {
        let query = StorageQuery(categories: [.event])
        return await storage.entries(matching: query).compactMap { $0 as? Event }
    }
}
