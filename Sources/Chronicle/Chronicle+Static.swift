import Foundation
import CloudKit
import TagAlong

@available(iOS 17, macOS 14, *)
extension Chronicle {
	
	/// Tracks a named event with optional context.
	nonisolated public static func track(_ name: String, description: String? = nil, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.events.track(name, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
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
	
	/// Tracks a screen transition in the app flow.
	nonisolated public static func flow(_ name: String, description: String? = nil, transition: TransitionType = .push, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.flow.trackScreen(name, transition: transition, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}
	
	/// Logs an error with optional severity and context.
	nonisolated public static func error(
		_ error: Error,
		description: String? = nil,
		severity: ErrorSeverity = .error,
		context: EventMetadata? = nil,
		captureCallStack: Bool = false,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let merged = mergeDescription(description, into: context)
		instance.errors.log(
			error,
			severity: severity,
			context: merged,
			captureCallStack: captureCallStack,
			tags: tags,
			referenceURL: referenceURL,
			referenceID: referenceID,
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
		record: CKRecord? = nil,
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
		instance.cloudKit.logUpload(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, record: record, context: merged, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
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
		record: CKRecord? = nil,
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
		instance.cloudKit.logDownload(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, record: record, context: merged, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit record deletion.
	nonisolated public static func cloudKitDelete(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
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
		instance.cloudKit.logDeletion(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			context: merged, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit zone creation.
	nonisolated public static func cloudKitZoneCreated(
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
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
		instance.cloudKit.logZoneCreated(
			zoneName: zoneName, zoneOwner: zoneOwner,
			context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit zone creation from a zone ID.
	nonisolated public static func cloudKitZoneCreated(
		zoneID: CKRecordZone.ID,
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
		instance.cloudKit.logZoneCreated(
			zoneID: zoneID,
			context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit zone deletion.
	nonisolated public static func cloudKitZoneDeleted(
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
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
		instance.cloudKit.logZoneDeleted(
			zoneName: zoneName, zoneOwner: zoneOwner,
			context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit zone deletion from a zone ID.
	nonisolated public static func cloudKitZoneDeleted(
		zoneID: CKRecordZone.ID,
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
		instance.cloudKit.logZoneDeleted(
			zoneID: zoneID,
			context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs an error with a string context.
	nonisolated public static func error(_ error: Error, description: String? = nil, severity: ErrorSeverity = .error, context: String, captureCallStack: Bool = false, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		if error.isCancellation { return }
		var metadata: EventMetadata = ["context": .string(context)]
		if let description { metadata["description"] = .string(description) }
		self.error(error, severity: severity, context: metadata, captureCallStack: captureCallStack, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}
}

@available(iOS 17, macOS 14, *)
private func mergeDescription(_ description: String?, into context: EventMetadata?) -> EventMetadata? {
	guard let description else { return context }
	var result = context ?? EventMetadata()
	result["description"] = .string(description)
	return result
}

fileprivate extension Error {
	var isCancellation: Bool {
		if self is CancellationError { return true }
		  
		return abs((self as NSError).code) == 999
	}
}
