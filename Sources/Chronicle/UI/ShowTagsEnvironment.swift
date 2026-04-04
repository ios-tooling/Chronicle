import SwiftUI
import TagAlong

@available(iOS 17, macOS 14, *)
extension EnvironmentValues {
	@Entry public var showTags = true
	@Entry public var referenceIDTapAction: (@MainActor (String) -> Void)? = nil
	@Entry public var tagTapAction: (@MainActor (Tag) -> Void)? = nil
}
