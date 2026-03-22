import Foundation

/// Represents a tracked application event.
public struct Event: ChronicleEntry {
    public let id: UUID
    public let timestamp: Date
    public let category: EntryCategory = .event
    public let name: String
    public let metadata: EventMetadata?
    public let sourceFile: String?
    public let sourceFunction: String?
    public let sourceLine: Int?

    public init(id: UUID = UUID(), timestamp: Date = Date(), name: String, metadata: EventMetadata? = nil, sourceFile: String? = nil, sourceFunction: String? = nil, sourceLine: Int? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.name = name
        self.metadata = metadata
        self.sourceFile = sourceFile
        self.sourceFunction = sourceFunction
        self.sourceLine = sourceLine
    }

	public func matches(filter: String) -> Bool {
		name.localizedCaseInsensitiveContains(filter)
	}

    // Custom Codable to handle the constant category
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, category, name, metadata
        case sourceFile, sourceFunction, sourceLine
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(sourceFile, forKey: .sourceFile)
        try container.encodeIfPresent(sourceFunction, forKey: .sourceFunction)
        try container.encodeIfPresent(sourceLine, forKey: .sourceLine)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        name = try container.decode(String.self, forKey: .name)
        metadata = try container.decodeIfPresent(EventMetadata.self, forKey: .metadata)
        sourceFile = try container.decodeIfPresent(String.self, forKey: .sourceFile)
        sourceFunction = try container.decodeIfPresent(String.self, forKey: .sourceFunction)
        sourceLine = try container.decodeIfPresent(Int.self, forKey: .sourceLine)
    }
}
