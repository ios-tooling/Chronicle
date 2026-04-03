import SwiftUI
import TagAlong

@available(iOS 17, macOS 14, *)
struct ShowTagsKey: EnvironmentKey {
	static let defaultValue = true
}

@available(iOS 17, macOS 14, *)
struct TagTapActionKey: EnvironmentKey {
	static let defaultValue: (@MainActor (Tag) -> Void)? = nil
}

@available(iOS 17, macOS 14, *)
struct ReferenceIDTapActionKey: EnvironmentKey {
	static let defaultValue: (@MainActor @Sendable (String) -> Void)? = nil
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

	/// Closure called when an entry with a referenceID is tapped.
	public var referenceIDTapAction: (@MainActor @Sendable (String) -> Void)? {
		get { self[ReferenceIDTapActionKey.self] }
		set { self[ReferenceIDTapActionKey.self] = newValue }
	}
}
