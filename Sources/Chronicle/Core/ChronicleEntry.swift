import Foundation

/// A string-backed category identifier for Chronicle entries. Extensible with custom categories.
public struct EntryCategory: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }

    public static let event = EntryCategory("event")
    public static let network = EntryCategory("network")
    public static let flow = EntryCategory("flow")
    public static let error = EntryCategory("error")

    /// The four built-in categories.
    public static let builtIn: [EntryCategory] = [.event, .network, .flow, .error]
}

/// Base protocol for all Chronicle log entries.
public protocol ChronicleEntry: Codable, Sendable {
	var id: UUID { get }
	var timestamp: Date { get }
	var category: EntryCategory { get }
	func matches(filter: String) -> Bool
	var displaySummary: String { get }
	var sourceFile: String? { get }
	var sourceFunction: String? { get }
	var sourceLine: Int? { get }
}

extension ChronicleEntry {
	public var displaySummary: String { category.displayName }
	public func matches(filter: String) -> Bool { false }
}
