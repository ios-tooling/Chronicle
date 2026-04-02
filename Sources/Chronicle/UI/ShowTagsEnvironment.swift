import SwiftUI
import TagAlong

@available(iOS 17, macOS 14, *)
struct ShowTagsKey: EnvironmentKey {
	static let defaultValue = true
}

@available(iOS 17, macOS 14, *)
struct TagTapActionKey: EnvironmentKey {
	nonisolated(unsafe) static let defaultValue: (@MainActor (Tag) -> Void)? = nil
}

@available(iOS 17, macOS 14, *)
extension EnvironmentValues {
	var showTags: Bool {
		get { self[ShowTagsKey.self] }
		set { self[ShowTagsKey.self] = newValue }
	}

	var tagTapAction: (@MainActor (Tag) -> Void)? {
		get { self[TagTapActionKey.self] }
		set { self[TagTapActionKey.self] = newValue }
	}
}
