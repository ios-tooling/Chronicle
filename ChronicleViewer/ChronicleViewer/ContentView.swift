import SwiftUI
import Chronicle
import SwiftData

struct ContentView: View {
	@State private var selectedURL: URL?
	@State private var watcher: DatabaseWatcher?
	@State private var model: ChronicleViewerModel?
	@State private var showClearConfirmation = false
	@State private var errorMessage: String?
	@State private var isRefreshing = false
	@State private var securityScopedURL: URL?
	@AppStorage("lastDatabaseBookmark") private var lastDatabaseBookmark: Data = Data()

	var body: some View {
		Group {
			if model != nil, let watcher {
				viewerContent(watcher: watcher)
			} else {
				welcomeView
			}
		}
		.frame(minWidth: 600, minHeight: 400)
		.task { restoreFromBookmark() }
	}

	private var welcomeView: some View {
		VStack(spacing: 20) {
			Image(systemName: "doc.text.magnifyingglass")
				.font(.system(size: 48))
				.foregroundStyle(.secondary)

			Text("Chronicle Viewer")
				.font(.title)

			Text("Open a Chronicle database directory to view its contents.")
				.foregroundStyle(.secondary)

			Button("Open Database…") { selectDatabase() }
				.buttonStyle(.borderedProminent)
				.keyboardShortcut(.defaultAction)

			if let errorMessage {
				Text(errorMessage)
					.foregroundStyle(.red)
					.font(.caption)
			}
		}
		.padding(40)
	}

	private func viewerContent(watcher: DatabaseWatcher) -> some View {
		VStack(spacing: 0) {
			toolbar
			LiveChronicleView(model: $model, directoryURL: selectedURL!, watcher: watcher, showClearConfirmation: $showClearConfirmation, isRefreshing: $isRefreshing)
		}
	}

	private var toolbar: some View {
		HStack {
			if let url = selectedURL {
				Image(systemName: "cylinder")
					.foregroundStyle(.secondary)
				Text(url.path(percentEncoded: false))
					.font(.caption.monospaced())
					.foregroundStyle(.secondary)
					.lineLimit(1)
					.truncationMode(.head)
			}
			Spacer()
            ProgressView()
                .scaleEffect(0.7)
                .transition(.opacity)
                .opacity(isRefreshing ? 1 : 0)

			if let watcher {
				Button {
					watcher.manualRefresh()
				} label: {
					Image(systemName: "arrow.clockwise")
				}
				.buttonStyle(.bordered)
				.help("Reload from disk")
				.disabled(isRefreshing)
			}
			Button("Open…") { selectDatabase() }
				.buttonStyle(.bordered)
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
		.background(.bar)
		.animation(.easeInOut(duration: 0.2), value: isRefreshing)
	}

	private func selectDatabase() {
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

		// Create security-scoped bookmark before the panel releases access
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

	private func restoreFromBookmark() {
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

	private func stopCurrentAccess() {
		securityScopedURL?.stopAccessingSecurityScopedResource()
		securityScopedURL = nil
	}

	/// Accepts a history.db file, a directory containing one, a subdirectory of
	/// one, or walks up two levels to find a parent that contains one.
	private func resolveDirectoryURL(from url: URL) -> URL? {
		let fm = FileManager.default

		func containsDB(_ dir: URL) -> Bool {
			fm.fileExists(atPath: dir.appendingPathComponent("history.db").path)
		}

		// Selected the file directly
		if url.lastPathComponent == "history.db" { return url.deletingLastPathComponent() }

		let baseDir = url.hasDirectoryPath ? url : url.deletingLastPathComponent()

		// Check the selected directory itself
		if containsDB(baseDir) { return baseDir }

		// Check one level down (e.g. selected an app container that holds com.chronicle.history/)
		if let subdirs = try? fm.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: [.isDirectoryKey]) {
			for sub in subdirs where containsDB(sub) { return sub }
		}

		// Walk up two levels
		var candidate = baseDir.deletingLastPathComponent()
		for _ in 0..<2 {
			if containsDB(candidate) { return candidate }
			candidate = candidate.deletingLastPathComponent()
		}

		return nil
	}

	private func openDatabase(at directoryURL: URL) {
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

/// Wraps ChronicleTabContent and rebuilds the ModelContainer when the database
/// file changes on disk, so @Query picks up writes from external processes.
struct LiveChronicleView: View {
	@Binding var model: ChronicleViewerModel?
	let directoryURL: URL
	@ObservedObject var watcher: DatabaseWatcher
	@Binding var showClearConfirmation: Bool
	@Binding var isRefreshing: Bool
	@State private var isAtTop = true

	var body: some View {
		ScrollViewReader { proxy in
			Group {
				if let model {
					ChronicleTabContent(model: model, showClearConfirmation: $showClearConfirmation, currentRunOnly: false)
						.modelContainer(model.modelContainer)
				}
			}
			.onChange(of: watcher.refreshToken) {
				refresh(proxy: proxy)
			}
		}
		.onScrollGeometryChange(for: Bool.self) { geo in
			geo.contentOffset.y <= geo.contentInsets.top + 10
		} action: { _, atTop in
			isAtTop = atTop
		}
	}

	private func refresh(proxy: ScrollViewProxy) {
		let shouldScrollToTop = isAtTop
		withAnimation { isRefreshing = true }
		Task { @MainActor in
			do {
				let container = try SwiftDataStorage.containerForExternalDatabase(at: directoryURL)
				let config = ChronicleConfiguration(isReadOnly: true, modelContainer: container)
				try Chronicle.instance.configure(config)
				model = ChronicleViewerModel(modelContainer: container)
			} catch {}
			try? await Task.sleep(for: .milliseconds(500))
			withAnimation {
				isRefreshing = false
				if shouldScrollToTop {
					proxy.scrollTo(ChronicleEntryList.topAnchorID, anchor: .top)
				}
			}
		}
	}
}
