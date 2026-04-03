import Foundation
@_exported import TagAlong

/// A string-backed category identifier for Chronicle entries. Extensible with custom categories.
public struct EntryCategory: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }

    public static let event = EntryCategory("event")
    public static let network = EntryCategory("network")
    public static let flow = EntryCategory("flow")
    public static let error = EntryCategory("error")
    public static let cloudKitUpload = EntryCategory("cloudKitUpload")
    public static let cloudKitDownload = EntryCategory("cloudKitDownload")

    /// The built-in categories.
    public static let builtIn: [EntryCategory] = [.event, .network, .flow, .error, .cloudKitUpload, .cloudKitDownload]
}

/// Base protocol for all Chronicle log entries.
public protocol ChronicleEntry: Codable, Sendable {
	var id: UUID { get }
	var timestamp: Date { get }
	var category: EntryCategory { get }
	var tags: [Tag]? { get }
	func matches(filter: String) -> Bool
	var displaySummary: String { get }
	var referenceURL: URL? { get }
	var referenceID: String? { get }
	var sourceFile: String? { get }
	var sourceFunction: String? { get }
	var sourceLine: Int? { get }
}

extension ChronicleEntry {
	public var displaySummary: String { category.displayName }
	public func matches(filter: String) -> Bool { false }
	public var tags: [Tag]? { nil }
	public var referenceURL: URL? { nil }
	public var referenceID: String? { nil }
}
