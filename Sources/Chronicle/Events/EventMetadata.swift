import Foundation

/// A typed metadata container for event properties.
public struct EventMetadata: Codable, Sendable, Hashable {
    private var storage: [String: AnyCodableValue]

    /// Creates metadata from a dictionary.
    public init(_ dictionary: [String: AnyCodableValue] = [:]) {
        self.storage = dictionary
    }

    /// Access metadata values by key.
    public subscript(key: String) -> AnyCodableValue? {
        get { storage[key] }
        set { storage[key] = newValue }
    }

    /// All keys in the metadata.
    public var keys: Dictionary<String, AnyCodableValue>.Keys {
        storage.keys
    }

    /// Whether the metadata is empty.
    public var isEmpty: Bool {
        storage.isEmpty
    }

    /// The number of entries.
    public var count: Int {
        storage.count
    }

    /// Returns the underlying dictionary.
    public var dictionary: [String: AnyCodableValue] {
        storage
    }
}

extension EventMetadata: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnyCodableValue)...) {
        self.storage = Dictionary(uniqueKeysWithValues: elements)
    }
}

extension EventMetadata: CustomStringConvertible {
    public var description: String {
        let pairs = storage.map { "\($0.key): \($0.value)" }
        return "[\(pairs.joined(separator: ", "))]"
    }
}
