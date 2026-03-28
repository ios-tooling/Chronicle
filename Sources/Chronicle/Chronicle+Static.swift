import Foundation
import TagAlong

@available(iOS 17, macOS 14, *)
extension Chronicle {
	
	/// Tracks a named event with optional metadata.
	nonisolated public static func track(_ name: String, metadata: EventMetadata? = nil, tags: [Tag] = [], file: String = #file, function: String = #function, line: Int = #line) {
		instance.events.track(name, metadata: metadata, tags: tags, file: file, function: function, line: line)
	}
	
	/// Logs a network request and response from a URLRequest/HTTPURLResponse pair.
	nonisolated public static func network(
		request: URLRequest,
		response: HTTPURLResponse? = nil,
		data: Data? = nil,
		error: Error? = nil,
		wasCancelled: Bool = false,
		metrics: NetworkMetrics? = nil,
		linkedErrorID: UUID? = nil,
		tags: [Tag] = [],
		startTime: Date = Date(),
		endTime: Date? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
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
				tags: tags,
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
				tags: tags,
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
		tags: [Tag] = [],
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
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
			tags: tags,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function,
			sourceLine: line
		)
		instance.network.log(log)
	}
	
	/// Tracks a screen transition in the app flow.
	nonisolated public static func flow(_ name: String, transition: TransitionType = .push, metadata: EventMetadata? = nil, tags: [Tag] = [], file: String = #file, function: String = #function, line: Int = #line) {
		instance.flow.trackScreen(name, transition: transition, metadata: metadata, tags: tags, file: file, function: function, line: line)
	}
	
	/// Logs an error with optional severity and context.
	nonisolated public static func error(
		_ error: Error,
		severity: ErrorSeverity = .error,
		context: EventMetadata? = nil,
		captureCallStack: Bool = false,
		tags: [Tag] = [],
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		instance.errors.log(
			error,
			severity: severity,
			context: context,
			captureCallStack: captureCallStack,
			tags: tags,
			file: file,
			function: function,
			line: line
		)
	}
	
	/// Logs a CloudKit record upload.
	nonisolated public static func cloudKitUpload(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		tags: [Tag] = [],
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		instance.cloudKit.logUpload(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, tags: tags,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit record download.
	nonisolated public static func cloudKitDownload(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		tags: [Tag] = [],
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		instance.cloudKit.logDownload(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, tags: tags,
			file: file, function: function, line: line
		)
	}

	/// Logs an error with a string context.
	nonisolated public static func error(_ error: Error, severity: ErrorSeverity = .error, context: String, captureCallStack: Bool = false, tags: [Tag] = [], file: String = #file, function: String = #function, line: Int = #line) {
		if error.isCancellation { return }
		let metadata: EventMetadata = ["context": .string(context)]
		self.error(error, severity: severity, context: metadata, captureCallStack: captureCallStack, tags: tags, file: file, function: function, line: line)
	}
}

fileprivate extension Error {
	var isCancellation: Bool {
		if self is CancellationError { return true }
		  
		return abs((self as NSError).code) == 999
	}
}
