import Foundation

@available(iOS 17, macOS 14, *)
extension Chronicle {
	/// The observable count of errors logged in this app session.
	///
	/// ```swift
	/// ContentScreen()
	/// 	.tabItem { Label("Log", systemImage: "list.bullet") }
	/// 	.badge(Chronicle.newErrors.count)
	/// ```
	nonisolated public static var newErrors: NewErrorCounter { instance.newErrors }

	/// The number of errors logged in this app session, e.g. `.badge(Chronicle.newErrorCount)`.
	@MainActor public static var newErrorCount: Int { instance.newErrors.count }

	/// Resets the new-errors count to 0. Opening the Chronicle viewer does this automatically.
	@MainActor public static func clearNewErrors() { instance.newErrors.clear() }
}
