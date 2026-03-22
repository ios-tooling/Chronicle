import Foundation

/// Logs network requests and responses.
public final class NetworkLogger: Sendable {
    private let storage: SwiftDataStorage
    private let errorTracker: ErrorTracker?

    init(storage: SwiftDataStorage, errorTracker: ErrorTracker? = nil) {
        self.storage = storage
        self.errorTracker = errorTracker
    }

    /// Manually log a network request/response.
    /// If an error is provided and an ErrorTracker is available, automatically creates a linked ErrorLog.
    public func log(request: URLRequest, response: HTTPURLResponse? = nil, data: Data? = nil, error: Error? = nil, startTime: Date = Date(), endTime: Date? = nil, file: String = #file, function: String = #function, line: Int = #line) {
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
            metrics: NetworkMetrics(
                startTime: startTime,
                endTime: endTime ?? Date(),
                bytesSent: Int64(request.httpBody?.count ?? 0),
                bytesReceived: Int64(data?.count ?? 0)
            ),
            linkedErrorID: linkedErrorID,
            sourceFile: (file as NSString).lastPathComponent,
            sourceFunction: function,
            sourceLine: line
        )
        storage.store(networkLog)
    }

    /// Log a pre-built NetworkLog entry directly.
    public func log(_ networkLog: NetworkLog) {
        storage.store(networkLog)
    }

    /// Returns recent network logs, up to the specified limit.
    public func recentLogs(limit: Int = 100) -> [NetworkLog] {
        let query = StorageQuery(categories: [.network], limit: limit)
        return storage.entries(matching: query).compactMap { $0 as? NetworkLog }
    }

    /// Returns all stored network logs.
    public func allLogs() -> [NetworkLog] {
        let query = StorageQuery(categories: [.network])
        return storage.entries(matching: query).compactMap { $0 as? NetworkLog }
    }

}
