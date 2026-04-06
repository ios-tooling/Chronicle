import SwiftUI
import SwiftData
import Chronicle

extension ContentView {
	func selectDatabase() {
		let panel = NSOpenPanel()
		panel.canChooseFiles = true
		panel.canChooseDirectories = true
		panel.allowsMultipleSelection = false
		panel.message = "Select a Chronicle database file or directory"
		panel.prompt = "Open"

		guard panel.runModal() == .OK, let url = panel.url else { return }
		guard let resolved = resolveDirectoryURL(from: url) else {
			errorMessage = "No history.db found near \(url.lastPathComponent)"
			return
		}

		if let bookmark = try? resolved.bookmarkData(
			options: .withSecurityScope,
			includingResourceValuesForKeys: nil,
			relativeTo: nil
		) {
			lastDatabaseBookmark = bookmark
		}

		stopCurrentAccess()
		_ = resolved.startAccessingSecurityScopedResource()
		securityScopedURL = resolved
		openDatabase(at: resolved)
	}

	func restoreFromBookmark() {
		guard !lastDatabaseBookmark.isEmpty else { return }
		do {
			var isStale = false
			let url = try URL(
				resolvingBookmarkData: lastDatabaseBookmark,
				options: .withSecurityScope,
				relativeTo: nil,
				bookmarkDataIsStale: &isStale
			)
			if isStale {
				lastDatabaseBookmark = Data()
				return
			}
			_ = url.startAccessingSecurityScopedResource()
			securityScopedURL = url
			openDatabase(at: url)
		} catch {
			lastDatabaseBookmark = Data()
		}
	}

	func stopCurrentAccess() {
		securityScopedURL?.stopAccessingSecurityScopedResource()
		securityScopedURL = nil
	}

	/// Accepts a history.db file, a directory containing one, a subdirectory of
	/// one, or walks up two levels to find a parent that contains one.
	func resolveDirectoryURL(from url: URL) -> URL? {
		let fm = FileManager.default

		func containsDB(_ dir: URL) -> Bool {
			fm.fileExists(atPath: dir.appendingPathComponent("history.db").path)
		}

		if url.lastPathComponent == "history.db" { return url.deletingLastPathComponent() }

		let baseDir = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
		if containsDB(baseDir) { return baseDir }

		if let subdirs = try? fm.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: [.isDirectoryKey]) {
			for sub in subdirs where containsDB(sub) { return sub }
		}

		var candidate = baseDir.deletingLastPathComponent()
		for _ in 0..<2 {
			if containsDB(candidate) { return candidate }
			candidate = candidate.deletingLastPathComponent()
		}

		return nil
	}

	func openDatabase(at directoryURL: URL) {
		let dbURL = directoryURL.appendingPathComponent("history.db")
		guard FileManager.default.fileExists(atPath: dbURL.path) else {
			errorMessage = "No history.db found in \(directoryURL.lastPathComponent)"
			return
		}

		do {
			let container = try SwiftDataStorage.containerForExternalDatabase(at: directoryURL)
			let config = ChronicleConfiguration(isReadOnly: true, modelContainer: container)
			try Chronicle.instance.configure(config)

			withAnimation {
				self.selectedURL = directoryURL
				self.watcher = DatabaseWatcher(dbURL: dbURL, modelContainer: container)
				self.model = ChronicleViewerModel(modelContainer: container)
				self.errorMessage = nil
			}
		} catch {
			errorMessage = "Failed to open database at \(directoryURL.path(percentEncoded: false)): \(error.localizedDescription)"
		}
	}
}
