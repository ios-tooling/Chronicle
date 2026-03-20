import Foundation

/// Logs network requests and responses.
public final class NetworkLogger: Sendable {
    private let storage: SwiftDataStorage

    init(storage: SwiftDataStorage) {
        self.storage = storage
    }

    /// Manually log a network request/response.
    public func log(
        request: URLRequest,
        response: HTTPURLResponse? = nil,
        data: Data? = nil,
        error: Error? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil
    ) {
        let networkLog = NetworkLog(
            url: request.url ?? URL(string: "https://unknown")!,
            method: request.httpMethod ?? "GET",
            requestHeaders: request.allHTTPHeaderFields,
            requestBodySize: request.httpBody?.count,
            statusCode: response?.statusCode,
            responseHeaders: response?.allHeaderFields as? [String: String],
            responseBodySize: data?.count,
            error: error?.localizedDescription,
            metrics: NetworkMetrics(
                startTime: startTime,
                endTime: endTime ?? Date(),
                bytesSent: Int64(request.httpBody?.count ?? 0),
                bytesReceived: Int64(data?.count ?? 0)
            )
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

    /// Creates a URLSession configuration with automatic network interception enabled.
    public func interceptingSessionConfiguration(
        baseConfiguration: URLSessionConfiguration = .default
    ) -> URLSessionConfiguration {
        let config = baseConfiguration
        var protocols = config.protocolClasses ?? []
        protocols.insert(URLSessionInterceptor.self, at: 0)
        config.protocolClasses = protocols
        URLSessionInterceptor.networkLogger = self
        return config
    }
}
