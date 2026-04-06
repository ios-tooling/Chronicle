import Foundation
import TagAlong

@available(iOS 17, macOS 14, *)
extension Chronicle {
	/// Tracks a screen transition in the app flow.
	nonisolated public static func flow(_ name: String, description: String? = nil, transition: TransitionType = .push, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.flow.trackScreen(name, transition: transition, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}
}
