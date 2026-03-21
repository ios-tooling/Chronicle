import Foundation

/// Represents a navigation transition between two screens.
public struct FlowEvent: ChronicleEntry {
    public let id: UUID
    public let timestamp: Date
    public let category: EntryCategory = .flow

    /// The screen navigated from. Nil for the first screen.
    public let from: FlowStep?

    /// The screen navigated to.
    public let to: FlowStep

    /// The type of transition.
    public let transitionType: TransitionType

    public let sourceFile: String?
    public let sourceFunction: String?
    public let sourceLine: Int?

    public init(id: UUID = UUID(), timestamp: Date = Date(), from: FlowStep? = nil, to: FlowStep, transitionType: TransitionType = .push, sourceFile: String? = nil, sourceFunction: String? = nil, sourceLine: Int? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.from = from
        self.to = to
        self.transitionType = transitionType
        self.sourceFile = sourceFile
        self.sourceFunction = sourceFunction
        self.sourceLine = sourceLine
    }

    // Custom Codable to handle the constant category
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, category, from, to, transitionType
        case sourceFile, sourceFunction, sourceLine
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(from, forKey: .from)
        try container.encode(to, forKey: .to)
        try container.encode(transitionType, forKey: .transitionType)
        try container.encodeIfPresent(sourceFile, forKey: .sourceFile)
        try container.encodeIfPresent(sourceFunction, forKey: .sourceFunction)
        try container.encodeIfPresent(sourceLine, forKey: .sourceLine)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.from = try container.decodeIfPresent(FlowStep.self, forKey: .from)
        to = try container.decode(FlowStep.self, forKey: .to)
        transitionType = try container.decode(TransitionType.self, forKey: .transitionType)
        sourceFile = try container.decodeIfPresent(String.self, forKey: .sourceFile)
        sourceFunction = try container.decodeIfPresent(String.self, forKey: .sourceFunction)
        sourceLine = try container.decodeIfPresent(Int.self, forKey: .sourceLine)
    }
}
