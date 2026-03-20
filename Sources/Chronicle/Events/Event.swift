import Foundation

/// Represents a tracked application event.
public struct Event: ChronicleEntry {
    public let id: UUID
    public let timestamp: Date
    public let category: EntryCategory = .event
    public let name: String
    public let metadata: EventMetadata?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        name: String,
        metadata: EventMetadata? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.name = name
        self.metadata = metadata
    }

    // Custom Codable to handle the constant category
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, category, name, metadata
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        name = try container.decode(String.self, forKey: .name)
        metadata = try container.decodeIfPresent(EventMetadata.self, forKey: .metadata)
    }
}
