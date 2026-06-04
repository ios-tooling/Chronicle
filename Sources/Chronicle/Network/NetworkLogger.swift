import Foundation
import TagAlong

/// Logs network requests and responses.
@available(iOS 17, macOS 14, *)
public final class NetworkLogger: Sendable {
    private let storage: SwiftDataStorage
    private let writer: StorageWriter
    private let errorTracker: ErrorTracker?

    init(storage: SwiftDataStorage, writer: StorageWriter, errorTracker: ErrorTracker? = nil) {
        self.storage = storage
        self.writer = writer
        self.errorTracker = errorTracker
    }

    /// Manually log a network request/response.
    /// If an error is provided and an ErrorTracker is available, automatically creates a linked ErrorLog.
    public func log(request: URLRequest, response: HTTPURLResponse? = nil, data: Data? = nil, error: Error? = nil, wasCancelled: Bool = false, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, startTime: Date = Date(), endTime: Date? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let networkLogID = UUID()
        var linkedErrorID: UUID?

        if let error, let errorTracker {
            let errorLogID = UUID()
            linkedErrorID = errorLogID
            let errorLog = errorTracker.makeErrorLog(from: error, id: errorLogID, linkedNetworkLogID: networkLogID, file: file, function: function, line: line)
            errorTracker.log(errorLog)
        }

        let networkLog = NetworkLog(
            id: networkLogID,
            url: request.url ?? URL(string: "https://unknown")!,
            method: request.httpMethod ?? "GET",
            requestHeaders: request.allHTTPHeaderFields,
            requestBody: request.httpBody,
            statusCode: response?.statusCode,
            responseHeaders: response?.allHeaderFields as? [String: String],
            responseBody: data,
            error: error?.localizedDescription,
            wasCancelled: wasCancelled,
            metrics: NetworkMetrics(
                startTime: startTime,
                endTime: endTime ?? Date(),
                bytesSent: Int64(request.httpBody?.count ?? 0),
                bytesReceived: Int64(data?.count ?? 0)
            ),
            linkedErrorID: linkedErrorID,
            context: context,
            tags: tags,
            referenceURL: referenceURL,
            referenceID: referenceID,
            sourceFile: (file as NSString).lastPathComponent,
            sourceFunction: function,
            sourceLine: line
        )
        writer.store(networkLog)
    }

    /// Log a pre-built NetworkLog entry directly.
    public func log(_ networkLog: NetworkLog) {
        writer.store(networkLog)
    }

    /// Returns recent network logs, up to the specified limit.
    public func recentLogs(limit: Int = 100) async -> [NetworkLog] {
        let query = StorageQuery(categories: [.network], limit: limit)
        return await storage.entries(matching: query).compactMap { $0 as? NetworkLog }
    }

    /// Returns all stored network logs.
    public func allLogs() async -> [NetworkLog] {
        let query = StorageQuery(categories: [.network])
        return await storage.entries(matching: query).compactMap { $0 as? NetworkLog }
    }

}
