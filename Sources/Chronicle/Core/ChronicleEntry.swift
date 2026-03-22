import Foundation

/// Categories of entries that Chronicle can track.
public enum EntryCategory: String, Codable, Sendable, CaseIterable {
    case event
    case network
    case flow
    case error
}

/// Base protocol for all Chronicle log entries.
public protocol ChronicleEntry: Codable, Sendable {
	var id: UUID { get }
	var timestamp: Date { get }
	var category: EntryCategory { get }
	func matches(filter: String) -> Bool
}
