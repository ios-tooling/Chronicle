import Foundation
import SwiftData

/// Configuration for the Chronicle framework.
@available(iOS 17, macOS 14, *)
public struct ChronicleConfiguration: Sendable {
    /// Whether Chronicle is actively recording entries.
    public var isEnabled: Bool

    /// The SwiftData model container used for persistence.
    /// If nil, Chronicle creates a default container.
    public var modelContainer: ModelContainer?

    /// Export destinations to send entries to.
    public var exportDestinations: [any ExportDestination]

    /// Creates a configuration with the specified options.
    public init(isEnabled: Bool = true, modelContainer: ModelContainer? = nil, exportDestinations: [any ExportDestination] = []) {
        self.isEnabled = isEnabled
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
