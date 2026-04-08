import Foundation
import TagAlong

@available(iOS 17, macOS 14, *)
extension Chronicle {
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
		instance.errors?.log(
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

	/// Logs an error with a string context.
	nonisolated public static func error(_ error: Error, description: String? = nil, severity: ErrorSeverity = .error, context: String, captureCallStack: Bool = false, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		if error.isCancellation { return }
		var metadata: EventMetadata = ["context": .string(context)]
		if let description { metadata["description"] = .string(description) }
		self.error(error, severity: severity, context: metadata, captureCallStack: captureCallStack, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}
}

extension Error {
	var isCancellation: Bool {
		if self is CancellationError { return true }
		return abs((self as NSError).code) == 999
	}
}
