import Foundation
import SwiftData

/// Chronicle is a framework for tracking events, logging network connections,
/// and determining the flow of an app.
///
/// Usage:
/// ```swift
/// // Configure (call once at app launch)
/// try Chronicle.shared.configure(.default)
///
/// // Track events
/// Chronicle.track("button_tapped", metadata: ["id": "checkout"])
///
/// // Log network requests
/// Chronicle.network(request: urlRequest, response: httpResponse, data: data)
///
/// // Track screen transitions
/// Chronicle.flow("HomeScreen", transition: .push)
///
/// // Log errors
/// Chronicle.error(someError, severity: .critical, context: ["screen": "checkout"])
///
/// // Generate a markdown report
/// let report = try Chronicle.shared.generateReport()
/// ```
@available(iOS 17, macOS 14, *)
public final class Chronicle: @unchecked Sendable {
    /// The shared Chronicle instance.
    public static let instance = Chronicle()

    private let lock = NSLock()
    private var _storage: SwiftDataStorage?
    private var _events: EventTracker?
    private var _network: NetworkLogger?
    private var _flow: FlowTracker?
    private var _errors: ErrorTracker?
    private var _cloudKit: CloudKitLogger?
    private var _configuration: ChronicleConfiguration?
    private var _launchDate: Date?

    private var storage: SwiftDataStorage? {
        lock.withLock { _storage }
    }

    /// The current configuration.
    public var configuration: ChronicleConfiguration {
        lock.withLock { _configuration ?? .default }
    }

    /// Whether Chronicle has been configured.
    public var isConfigured: Bool {
        lock.withLock { _storage != nil }
    }

    /// The date when Chronicle was configured (app launch).
    public var launchDate: Date? {
        lock.withLock { _launchDate }
    }

    /// The event tracker for recording application events.
    public var events: EventTracker {
        lock.withLock { _events! }
    }

    /// The network logger for recording network requests.
    public var network: NetworkLogger {
        lock.withLock { _network! }
    }

    /// The flow tracker for recording screen transitions.
    public var flow: FlowTracker {
        lock.withLock { _flow! }
    }

    /// The error tracker for logging arbitrary errors.
    public var errors: ErrorTracker {
        lock.withLock { _errors! }
    }

    /// The CloudKit logger for recording record uploads and downloads.
    public var cloudKit: CloudKitLogger {
        lock.withLock { _cloudKit! }
    }

    private init() {}

    /// Configures Chronicle with the given configuration.
    /// Must be called before using events, network, or flow trackers.
    public func configure(_ configuration: ChronicleConfiguration = .default) throws {
        let storage: SwiftDataStorage
        if let container = configuration.modelContainer {
            storage = try SwiftDataStorage(modelContainer: container)
        } else {
            storage = try SwiftDataStorage()
        }

        storage.maxEntries = configuration.maxEntries
        let errors = ErrorTracker(storage: storage)
        lock.withLock {
            self._launchDate = Date()
            self._configuration = configuration
            self._storage = storage
            self._events = EventTracker(storage: storage)
            self._errors = errors
            self._network = NetworkLogger(storage: storage, errorTracker: errors)
            self._flow = FlowTracker(storage: storage)
            self._cloudKit = CloudKitLogger(storage: storage)
        }
    }

    /// Configures Chronicle with an in-memory store (useful for testing).
    public func configureInMemory() throws {
        let storage = try SwiftDataStorage.inMemory()
        storage.maxEntries = ChronicleConfiguration.default.maxEntries
        let errors = ErrorTracker(storage: storage)
        lock.withLock {
            self._launchDate = Date()
            self._configuration = .default
            self._storage = storage
            self._events = EventTracker(storage: storage)
            self._errors = errors
            self._network = NetworkLogger(storage: storage, errorTracker: errors)
            self._flow = FlowTracker(storage: storage)
            self._cloudKit = CloudKitLogger(storage: storage)
        }
    }

    /// Stores a custom Chronicle entry.
    public func store(_ entry: any ChronicleEntry) {
        storage?.store(entry)
    }

    /// Returns all stored entries.
    public func allEntries() -> [any ChronicleEntry] {
        storage?.allEntries() ?? []
    }

    /// Returns entries matching the given query.
    public func entries(matching query: StorageQuery) -> [any ChronicleEntry] {
        storage?.entries(matching: query) ?? []
    }

    /// Clears all stored entries.
    public func clear() {
        storage?.clear()
    }

    /// Clears entries older than the given date.
    public func clear(before date: Date) {
        storage?.clear(before: date)
    }

    /// Clears entries from the given date onward.
    public func clear(since date: Date) {
        storage?.clear(since: date)
    }

//    /// Exports all entries to all configured destinations.
//    public func exportAll() throws {
//        let entries = allEntries()
//        let destinations = configuration.exportDestinations
//        for destination in destinations {
//            try destination.export(entries)
//        }
//    }

    /// Generates a markdown report for entries in the given time range.
    /// If no range is specified, includes all entries.
    public func generateReport(from startDate: Date? = nil, to endDate: Date? = nil, title: String = "Chronicle Report") throws -> String {
        let query = StorageQuery(since: startDate, until: endDate)
        let entries = storage?.entries(matching: query) ?? []
        let exporter = MarkdownExporter(title: title)
        return exporter.generateMarkdown(from: entries)
    }

    /// The SwiftData model container, for advanced usage.
    public var modelContainer: ModelContainer? {
        lock.withLock { _storage?.container }
    }
}
