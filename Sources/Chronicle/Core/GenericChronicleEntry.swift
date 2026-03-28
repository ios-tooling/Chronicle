import Foundation
import TagAlong

/// A generic Chronicle entry used for custom categories. Stores the full entry as JSON payload.
public struct GenericChronicleEntry: ChronicleEntry {
    public let id: UUID
    public let timestamp: Date
    public let category: EntryCategory
    public let summary: String
    public let payload: Data
    public let tags: [Tag]?
    public let sourceFile: String?
    public let sourceFunction: String?
    public let sourceLine: Int?

    public var displaySummary: String { summary }

    public func matches(filter: String) -> Bool {
        summary.localizedCaseInsensitiveContains(filter)
    }

    /// Decodes the stored payload as a specific type.
    public func decode<T: Decodable>(as type: T.Type) -> T? {
        try? JSONDecoder().decode(type, from: payload)
    }
}
