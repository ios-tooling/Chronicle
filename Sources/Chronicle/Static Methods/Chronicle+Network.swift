import Foundation
import TagAlong

@available(iOS 17, macOS 14, *)
extension Chronicle {
	/// Logs a network request and response from a URLRequest/HTTPURLResponse pair.
	nonisolated public static func network(
		request: URLRequest,
		response: HTTPURLResponse? = nil,
		data: Data? = nil,
		error: Error? = nil,
		wasCancelled: Bool = false,
		metrics: NetworkMetrics? = nil,
		linkedErrorID: UUID? = nil,
		description: String? = nil,
		context: EventMetadata? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		startTime: Date = Date(),
		endTime: Date? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let merged = mergeDescription(description, into: context)
		if metrics != nil || linkedErrorID != nil {
			let log = NetworkLog(
				url: request.url ?? URL(string: "https://unknown")!,
				method: request.httpMethod ?? "GET",
				requestHeaders: request.allHTTPHeaderFields,
				requestBody: request.httpBody,
				statusCode: response?.statusCode,
				responseHeaders: response?.allHeaderFields as? [String: String],
				responseBody: data,
				error: error?.localizedDescription,
				wasCancelled: wasCancelled,
				metrics: metrics ?? NetworkMetrics(startTime: startTime, endTime: endTime ?? Date(), bytesSent: Int64(request.httpBody?.count ?? 0), bytesReceived: Int64(data?.count ?? 0)),
				linkedErrorID: linkedErrorID,
				context: merged,
				tags: tags,
				referenceURL: referenceURL,
				referenceID: referenceID,
				sourceFile: (file as NSString).lastPathComponent,
				sourceFunction: function,
				sourceLine: line
			)
			instance.network.log(log)
		} else {
			instance.network.log(
				request: request,
				response: response,
				data: data,
				error: error,
				wasCancelled: wasCancelled,
				context: merged,
				tags: tags,
				referenceURL: referenceURL,
				referenceID: referenceID,
				startTime: startTime,
				endTime: endTime,
				file: file,
				function: function,
				line: line
			)
		}
	}

	/// Logs a network request and response from individual parameters.
	nonisolated public static func network(
		url: URL,
		method: String = "GET",
		requestHeaders: [String: String]? = nil,
		requestBody: Data? = nil,
		requestBodySize: Int? = nil,
		statusCode: Int? = nil,
		responseHeaders: [String: String]? = nil,
		responseBody: Data? = nil,
		responseBodySize: Int? = nil,
		error: String? = nil,
		wasCancelled: Bool = false,
		metrics: NetworkMetrics = NetworkMetrics(),
		linkedErrorID: UUID? = nil,
		description: String? = nil,
		context: EventMetadata? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let merged = mergeDescription(description, into: context)
		let log = NetworkLog(
			url: url,
			method: method,
			requestHeaders: requestHeaders,
			requestBody: requestBody,
			requestBodySize: requestBodySize,
			statusCode: statusCode,
			responseHeaders: responseHeaders,
			responseBody: responseBody,
			responseBodySize: responseBodySize,
			error: error,
			wasCancelled: wasCancelled,
			metrics: metrics,
			linkedErrorID: linkedErrorID,
			context: merged,
			tags: tags,
			referenceURL: referenceURL,
			referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function,
			sourceLine: line
		)
		instance.network.log(log)
	}
}
