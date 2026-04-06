import Foundation

@available(iOS 17, macOS 14, *)
func mergeDescription(_ description: String?, into context: EventMetadata?) -> EventMetadata? {
	guard let description else { return context }
	var result = context ?? EventMetadata()
	result["description"] = .string(description)
	return result
}
