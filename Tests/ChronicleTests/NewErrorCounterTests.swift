import Testing
import Foundation
@testable import Chronicle

@MainActor
@Suite("NewErrorCounter Tests")
struct NewErrorCounterTests {
	private func makeTracker() throws -> (ErrorTracker, NewErrorCounter) {
		let storage = try SwiftDataStorage.inMemory()
		let counter = NewErrorCounter()
		return (ErrorTracker(storage: storage, writer: StorageWriter(storage: storage), newErrors: counter), counter)
	}

	/// Polls on the main actor until `condition` holds, failing after a bounded timeout.
	private func waitUntil(_ condition: @MainActor () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async {
		let deadline = Date().addingTimeInterval(5)
		while !condition() {
			if Date() > deadline {
				Issue.record("Timed out waiting for condition", sourceLocation: sourceLocation)
				return
			}
			try? await Task.sleep(for: .milliseconds(5))
		}
	}

	/// Logs a sentinel `.error` and waits for exactly it to be counted, proving earlier logs were not counted.
	private func expectOnlySentinelCounted(_ tracker: ErrorTracker, _ counter: NewErrorCounter) async {
		tracker.log(TestError.simple, severity: .error)
		await waitUntil { counter.count >= 1 }
		#expect(counter.count == 1)
	}

	@Test("A fresh counter is zero")
	func freshCounterIsZero() {
		#expect(NewErrorCounter().count == 0)
	}

	@Test("Error and critical severities are counted", arguments: [ErrorSeverity.error, .critical])
	func countsErrorSeverities(_ severity: ErrorSeverity) async throws {
		let (tracker, counter) = try makeTracker()
		tracker.log(TestError.simple, severity: severity)
		await waitUntil { counter.count == 1 }
		#expect(counter.count == 1)
	}

	@Test("Lower severities are not counted", arguments: [ErrorSeverity.debug, .info, .warning])
	func ignoresLowerSeverities(_ severity: ErrorSeverity) async throws {
		let (tracker, counter) = try makeTracker()
		tracker.log(TestError.simple, severity: severity)
		await expectOnlySentinelCounted(tracker, counter)
	}

	@Test("Cancellations are not counted")
	func ignoresCancellations() async throws {
		let (tracker, counter) = try makeTracker()
		tracker.log(CancellationError(), severity: .error)
		tracker.log(NSError(domain: NSURLErrorDomain, code: -999), severity: .critical)
		await expectOnlySentinelCounted(tracker, counter)
	}

	@Test("Logging an ErrorLog directly counts once")
	func errorLogCountsOnce() async throws {
		let (tracker, counter) = try makeTracker()
		tracker.log(ErrorLog(domain: "Test", message: "boom", errorType: "TestError", fullDescription: "boom", severity: .error))
		await waitUntil { counter.count == 1 }
		tracker.log(ErrorLog(domain: "Test", message: "meh", errorType: "TestError", fullDescription: "meh", severity: .warning))
		tracker.log(TestError.simple, severity: .error)
		await waitUntil { counter.count >= 2 }
		#expect(counter.count == 2)
	}

	@Test("clear() resets to zero")
	func clearResets() async throws {
		let (tracker, counter) = try makeTracker()
		tracker.log(TestError.simple)
		tracker.log(TestError.simple)
		await waitUntil { counter.count == 2 }
		counter.clear()
		#expect(counter.count == 0)
	}

	@Test("Errors logged concurrently are all counted")
	func concurrentLogging() async throws {
		let (tracker, counter) = try makeTracker()
		let total = 50
		await withTaskGroup(of: Void.self) { group in
			for index in 0..<total {
				group.addTask { tracker.log(TestError.withMessage("error \(index)")) }
			}
		}
		await waitUntil { counter.count == total }
		#expect(counter.count == total)
	}

	@Test("Errors logged while a viewer is visible are not counted")
	func viewerSuppressesCounting() async throws {
		let (tracker, counter) = try makeTracker()
		tracker.log(TestError.simple)
		await waitUntil { counter.count == 1 }

		counter.viewerAppeared()
		#expect(counter.count == 0)
		let handledBefore = counter.recordsHandled
		for _ in 0..<5 { tracker.log(TestError.simple) }
		await waitUntil { counter.recordsHandled == handledBefore + 5 }
		#expect(counter.count == 0)

		counter.viewerDisappeared()
		#expect(counter.count == 0)
		await expectOnlySentinelCounted(tracker, counter)
	}
}
