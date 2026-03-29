import SwiftUI

@available(iOS 17, macOS 14, *)
struct ShowTagsKey: EnvironmentKey {
	static let defaultValue = true
}

@available(iOS 17, macOS 14, *)
extension EnvironmentValues {
	var showTags: Bool {
		get { self[ShowTagsKey.self] }
		set { self[ShowTagsKey.self] = newValue }
	}
}
