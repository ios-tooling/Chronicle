import Foundation
import SwiftData
import Combine

/// Watches a SQLite database file for changes from another process
/// and notifies SwiftData to re-fetch.
@MainActor
final class DatabaseWatcher: ObservableObject {
	private var source: DispatchSourceFileSystemObject?
	private var fileDescriptor: Int32 = -1
	private let dbURL: URL
	let modelContainer: ModelContainer
	@Published var refreshToken = UUID()

	init(dbURL: URL, modelContainer: ModelContainer) {
		self.dbURL = dbURL
		self.modelContainer = modelContainer
		startWatching()
	}

	deinit {
		source?.cancel()
		source = nil
	}

	private func startWatching() {
		// Watch the WAL file since SQLite writes there first
		let walURL = dbURL.appendingPathExtension("wal")
		let path = FileManager.default.fileExists(atPath: walURL.path) ? walURL.path : dbURL.path

		fileDescriptor = open(path, O_EVTONLY)
		guard fileDescriptor >= 0 else { return }

		let source = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: fileDescriptor,
			eventMask: [.write, .extend, .rename],
			queue: .main
		)

		source.setEventHandler { [weak self] in
			self?.refreshToken = UUID()
		}

		source.setCancelHandler { [fd = fileDescriptor] in
			close(fd)
		}

		self.source = source
		source.resume()
	}

	private func stopWatching() {
		source?.cancel()
		source = nil
	}
}
