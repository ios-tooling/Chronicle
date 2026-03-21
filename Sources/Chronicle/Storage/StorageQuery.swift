import Foundation

/// Defines filtering criteria for querying stored Chronicle entries.
public struct StorageQuery: Sendable {
    /// Filter by entry categories. Nil means all categories.
    public var categories: Set<EntryCategory>?

    /// Only include entries after this date.
    public var since: Date?

    /// Only include entries before this date.
    public var until: Date?

    /// Maximum number of entries to return.
    public var limit: Int?

    /// Filter events/flow entries whose name contains this string.
    public var nameContains: String?

    public init(categories: Set<EntryCategory>? = nil, since: Date? = nil, until: Date? = nil, limit: Int? = nil, nameContains: String? = nil) {
        self.categories = categories
        self.since = since
        self.until = until
        self.limit = limit
        self.nameContains = nameContains
    }

    /// A query that matches all entries.
    public static var all: StorageQuery { StorageQuery() }
}
