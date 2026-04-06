import Foundation
import TagAlong

@available(iOS 17, macOS 14, *)
extension Chronicle {
	/// Tracks a named event with optional context.
	nonisolated public static func track(_ name: String, description: String? = nil, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.events.track(name, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}
}
