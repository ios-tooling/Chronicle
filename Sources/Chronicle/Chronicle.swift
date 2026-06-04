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
/// Chronicle.track("button_tapped", context: ["id": "checkout"])
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
/// let report = await Chronicle.shared.generateReport()
/// ```
@available(iOS 17, macOS 14, *)
public final class Chronicle: @unchecked Sendable {
    /// The shared Chronicle instance.
    public static let instance = Chronicle()

    private let lock = NSLock()
    private var _storage: SwiftDataStorage?
    private var _writer: StorageWriter?
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

    private var writer: StorageWriter? {
        lock.withLock { _writer }
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
    public var events: EventTracker? {
        lock.withLock { _events }
    }

    /// The network logger for recording network requests.
    public var network: NetworkLogger? {
        lock.withLock { _network }
    }

    /// The flow tracker for recording screen transitions.
    public var flow: FlowTracker? {
        lock.withLock { _flow }
    }

    /// The error tracker for logging arbitrary errors.
    public var errors: ErrorTracker? {
        lock.withLock { _errors }
    }

    /// The CloudKit logger for recording record uploads and downloads.
    public var cloudKit: CloudKitLogger? {
        lock.withLock { _cloudKit }
    }

    /// Sets the maximum number of CKRecords to cache on disk. Pass 0 to disable (default).
    public func setCloudKitCacheSize(_ maxRecords: Int) {
        lock.withLock { _cloudKit?.setCacheSize(maxRecords) }
    }

    private init() {}

    /// Configures Chronicle with the given configuration.
    /// Must be called before using events, network, or flow trackers.
    public func configure(_ configuration: ChronicleConfiguration = .default) throws {
        let storage = try SwiftDataStorage.make(configuration: configuration)
        install(storage: storage, configuration: configuration, maxEntries: configuration.maxEntries)
    }

    /// Configures Chronicle with an in-memory store (useful for testing).
    public func configureInMemory() throws {
        let storage = try SwiftDataStorage.inMemory()
        install(storage: storage, configuration: .default, maxEntries: ChronicleConfiguration.default.maxEntries)
    }

    private func install(storage: SwiftDataStorage, configuration: ChronicleConfiguration, maxEntries: Int?) {
        let writer = StorageWriter(storage: storage)
        Task { await storage.setMaxEntries(maxEntries) }
        let errors = ErrorTracker(storage: storage, writer: writer)
        lock.withLock {
            self._launchDate = Date()
            self._configuration = configuration
            self._storage = storage
            self._writer = writer
            self._events = EventTracker(storage: storage, writer: writer)
            self._errors = errors
            self._network = NetworkLogger(storage: storage, writer: writer, errorTracker: errors)
            self._flow = FlowTracker(storage: storage, writer: writer)
            self._cloudKit = CloudKitLogger(storage: storage, writer: writer)
        }
    }

    /// Stores a custom Chronicle entry.
    public func store(_ entry: any ChronicleEntry) {
        writer?.store(entry)
    }

    /// Suspends until all enqueued writes have been persisted.
    public func flush() async {
        await writer?.flush()
    }

    /// Returns all stored entries.
    public func allEntries() async -> [any ChronicleEntry] {
        await storage?.allEntries() ?? []
    }

    /// Returns entries matching the given query.
    public func entries(matching query: StorageQuery) async -> [any ChronicleEntry] {
        await storage?.entries(matching: query) ?? []
    }

    /// Clears all stored entries.
    public func clear() async {
        await storage?.clear()
    }

    /// Clears entries older than the given date.
    public func clear(before date: Date) async {
        await storage?.clear(before: date)
    }

    /// Clears entries from the given date onward.
    public func clear(since date: Date) async {
        await storage?.clear(since: date)
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
    public func generateReport(from startDate: Date? = nil, to endDate: Date? = nil, title: String = "Chronicle Report") async -> String {
        let query = StorageQuery(since: startDate, until: endDate)
        let entries = await storage?.entries(matching: query) ?? []
        let exporter = MarkdownExporter(title: title)
        return exporter.generateMarkdown(from: entries)
    }

    /// The SwiftData model container, for advanced usage.
    public var modelContainer: ModelContainer? {
        lock.withLock { _storage?.container }
    }
}
