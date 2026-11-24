import Foundation
import Observation

/// The number of errors logged in this app session, for showing as a badge.
///
/// Only `.error` and `.critical` severities count, and cancellations never do. The count is
/// in memory only: it starts at 0 on each launch and is never persisted. Opening the Chronicle
/// viewer clears it, and errors logged while the viewer is on screen aren't counted.
///
/// Threading: `Chronicle.error` is nonisolated and callable from any thread, but the count lives
/// on the main actor so SwiftUI can read it directly. Logging hops to the main actor to update it,
/// so the count changes asynchronously, shortly after the log call returns.
@available(iOS 17, macOS 14, *)
@MainActor @Observable public final class NewErrorCounter {
	/// The number of new errors since launch or the last `clear()`.
	public private(set) var count = 0

	@ObservationIgnored private var visibleViewers = 0
	/// Every main-actor hop from `record()`, counted or dropped; lets tests wait deterministically.
	@ObservationIgnored private(set) var recordsHandled = 0

	nonisolated public init() {}

	/// Resets the count to 0.
	public func clear() {
		count = 0
	}

	/// Counts one new error, unless a viewer is on screen. Callable from any thread.
	nonisolated func record() {
		Task { @MainActor in self.handleRecord() }
	}

	private func handleRecord() {
		recordsHandled += 1
		if visibleViewers == 0 { count += 1 }
	}

	func viewerAppeared() {
		visibleViewers += 1
		clear()
	}

	func viewerDisappeared() {
		visibleViewers = max(0, visibleViewers - 1)
		clear()
	}
}

extension ErrorSeverity {
	/// Whether an error at this severity counts toward `NewErrorCounter`.
	var countsAsNewError: Bool {
		self == .error || self == .critical
	}
}
