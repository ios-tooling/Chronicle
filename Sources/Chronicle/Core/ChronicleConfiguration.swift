import Foundation
import SwiftData

/// Configuration for the Chronicle framework.
@available(iOS 17, macOS 14, *)
public struct ChronicleConfiguration: Sendable {
    /// Whether Chronicle is actively recording entries.
    public var isEnabled: Bool
    
    public var databaseLocation: URL?

    /// Whether to open the database read-only (e.g. for external viewer apps).
    public var isReadOnly: Bool

    /// Maximum number of entries to store across all types.
    /// Oldest entries are discarded when this limit is reached.
    public var maxEntries: Int

    /// The SwiftData model container used for persistence.
    /// If nil, Chronicle creates a default container.
    public var modelContainer: ModelContainer?

    /// Export destinations to send entries to.
    public var exportDestinations: [any ExportDestination]

    /// Creates a configuration with the specified options.
    public init(isEnabled: Bool = true, isReadOnly: Bool = false, maxEntries: Int = 1000, modelContainer: ModelContainer? = nil, exportDestinations: [any ExportDestination] = []) {
        self.isEnabled = isEnabled
        self.isReadOnly = isReadOnly
        self.maxEntries = maxEntries
        self.modelContainer = modelContainer
        self.exportDestinations = exportDestinations
    }

    /// Default configuration with Chronicle enabled and console export.
    public static var `default`: ChronicleConfiguration {
        ChronicleConfiguration(
            isEnabled: true,
            exportDestinations: [ConsoleExporter()]
        )
    }
}
