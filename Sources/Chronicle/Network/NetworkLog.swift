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
	public let requestBody: Data?
	public let requestBodySize: Int?
	
	// Response
	public let statusCode: Int?
	public let responseHeaders: [String: String]?
	public let responseBody: Data?
	public let responseBodySize: Int?
	public let error: String?
	
	// Metrics
	public let metrics: NetworkMetrics
	
	/// The UUID of a linked ErrorLog, if this request produced an error.
	public let linkedErrorID: UUID?
	
	public let sourceFile: String?
	public let sourceFunction: String?
	public let sourceLine: Int?
	
	public func matches(filter: String) -> Bool {
		url.absoluteString.localizedCaseInsensitiveContains(filter)
	}
	
	public init(
		id: UUID = UUID(),
		timestamp: Date = Date(),
		url: URL,
		method: String,
		requestHeaders: [String: String]? = nil,
		requestBody: Data? = nil,
		requestBodySize: Int? = nil,
		statusCode: Int? = nil,
		responseHeaders: [String: String]? = nil,
		responseBody: Data? = nil,
		responseBodySize: Int? = nil,
		error: String? = nil,
		metrics: NetworkMetrics = NetworkMetrics(),
		linkedErrorID: UUID? = nil,
		sourceFile: String? = nil,
		sourceFunction: String? = nil,
		sourceLine: Int? = nil
	) {
		self.id = id
		self.timestamp = timestamp
		self.url = url
		self.method = method
		self.requestHeaders = requestHeaders
		self.requestBody = requestBody
		self.requestBodySize = requestBodySize ?? requestBody?.count
		self.statusCode = statusCode
		self.responseHeaders = responseHeaders
		self.responseBody = responseBody
		self.responseBodySize = responseBodySize ?? responseBody?.count
		self.error = error
		self.metrics = metrics
		self.linkedErrorID = linkedErrorID
		self.sourceFile = sourceFile
		self.sourceFunction = sourceFunction
		self.sourceLine = sourceLine
	}
	
	// Custom Codable to handle the constant category
	private enum CodingKeys: String, CodingKey {
		case id, timestamp, category, url, method, requestHeaders, requestBody, requestBodySize
		case statusCode, responseHeaders, responseBody, responseBodySize, error, metrics
		case linkedErrorID, sourceFile, sourceFunction, sourceLine
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(timestamp, forKey: .timestamp)
		try container.encode(category, forKey: .category)
		try container.encode(url, forKey: .url)
		try container.encode(method, forKey: .method)
		try container.encodeIfPresent(requestHeaders, forKey: .requestHeaders)
		try container.encodeIfPresent(requestBody, forKey: .requestBody)
		try container.encodeIfPresent(requestBodySize, forKey: .requestBodySize)
		try container.encodeIfPresent(statusCode, forKey: .statusCode)
		try container.encodeIfPresent(responseHeaders, forKey: .responseHeaders)
		try container.encodeIfPresent(responseBody, forKey: .responseBody)
		try container.encodeIfPresent(responseBodySize, forKey: .responseBodySize)
		try container.encodeIfPresent(error, forKey: .error)
		try container.encode(metrics, forKey: .metrics)
		try container.encodeIfPresent(linkedErrorID, forKey: .linkedErrorID)
		try container.encodeIfPresent(sourceFile, forKey: .sourceFile)
		try container.encodeIfPresent(sourceFunction, forKey: .sourceFunction)
		try container.encodeIfPresent(sourceLine, forKey: .sourceLine)
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		timestamp = try container.decode(Date.self, forKey: .timestamp)
		url = try container.decode(URL.self, forKey: .url)
		method = try container.decode(String.self, forKey: .method)
		requestHeaders = try container.decodeIfPresent([String: String].self, forKey: .requestHeaders)
		requestBody = try container.decodeIfPresent(Data.self, forKey: .requestBody)
		requestBodySize = try container.decodeIfPresent(Int.self, forKey: .requestBodySize)
		statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
		responseHeaders = try container.decodeIfPresent([String: String].self, forKey: .responseHeaders)
		responseBody = try container.decodeIfPresent(Data.self, forKey: .responseBody)
		responseBodySize = try container.decodeIfPresent(Int.self, forKey: .responseBodySize)
		error = try container.decodeIfPresent(String.self, forKey: .error)
		metrics = try container.decode(NetworkMetrics.self, forKey: .metrics)
		linkedErrorID = try container.decodeIfPresent(UUID.self, forKey: .linkedErrorID)
		sourceFile = try container.decodeIfPresent(String.self, forKey: .sourceFile)
		sourceFunction = try container.decodeIfPresent(String.self, forKey: .sourceFunction)
		sourceLine = try container.decodeIfPresent(Int.self, forKey: .sourceLine)
	}
}
