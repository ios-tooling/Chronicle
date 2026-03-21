import Foundation

/// Protocol for destinations that Chronicle can export entries to.
public protocol ExportDestination: Sendable {
    /// Exports the given entries.
    /// Returns data if the export produces output (e.g., a file), nil otherwise.
    func export(_ entries: [any ChronicleEntry]) throws -> Data?
}
