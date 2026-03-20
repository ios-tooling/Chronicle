import Foundation

/// Represents a logged network request and its response.
public struct NetworkLog: ChronicleEntry {
    public let id: UUID
    public let timestamp: Date
    public let category: EntryCategory = .network

    // Request
    public let url: URL
    public let method: String
    public let requestHeaders: [String: String]?
    public let requestBodySize: Int?

    // Response
    public let statusCode: Int?
    public let responseHeaders: [String: String]?
    public let responseBodySize: Int?
    public let error: String?

    // Metrics
    public let metrics: NetworkMetrics

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        url: URL,
        method: String,
        requestHeaders: [String: String]? = nil,
        requestBodySize: Int? = nil,
        statusCode: Int? = nil,
        responseHeaders: [String: String]? = nil,
        responseBodySize: Int? = nil,
        error: String? = nil,
        metrics: NetworkMetrics = NetworkMetrics()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.url = url
        self.method = method
        self.requestHeaders = requestHeaders
        self.requestBodySize = requestBodySize
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.responseBodySize = responseBodySize
        self.error = error
        self.metrics = metrics
    }

    // Custom Codable to handle the constant category
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, category, url, method, requestHeaders, requestBodySize
        case statusCode, responseHeaders, responseBodySize, error, metrics
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(url, forKey: .url)
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(requestHeaders, forKey: .requestHeaders)
        try container.encodeIfPresent(requestBodySize, forKey: .requestBodySize)
        try container.encodeIfPresent(statusCode, forKey: .statusCode)
        try container.encodeIfPresent(responseHeaders, forKey: .responseHeaders)
        try container.encodeIfPresent(responseBodySize, forKey: .responseBodySize)
        try container.encodeIfPresent(error, forKey: .error)
        try container.encode(metrics, forKey: .metrics)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        url = try container.decode(URL.self, forKey: .url)
        method = try container.decode(String.self, forKey: .method)
        requestHeaders = try container.decodeIfPresent([String: String].self, forKey: .requestHeaders)
        requestBodySize = try container.decodeIfPresent(Int.self, forKey: .requestBodySize)
        statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        responseHeaders = try container.decodeIfPresent([String: String].self, forKey: .responseHeaders)
        responseBodySize = try container.decodeIfPresent(Int.self, forKey: .responseBodySize)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        metrics = try container.decode(NetworkMetrics.self, forKey: .metrics)
    }
}
