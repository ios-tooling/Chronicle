import SwiftUI
import Chronicle
import SwiftData

struct ContentView: View {
	@State private var selectedURL: URL?
	@State private var watcher: DatabaseWatcher?
	@State private var model: ChronicleViewerModel?
	@State private var showClearConfirmation = false
	@State private var errorMessage: String?

	var body: some View {
		Group {
			if model != nil, let watcher {
				viewerContent(watcher: watcher)
			} else {
				welcomeView
			}
		}
		.frame(minWidth: 600, minHeight: 400)
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
			LiveChronicleView(model: $model, directoryURL: selectedURL!, watcher: watcher, showClearConfirmation: $showClearConfirmation)
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
			Button("Open…") { selectDatabase() }
				.buttonStyle(.bordered)
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
		.background(.bar)
	}

	private func selectDatabase() {
		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.allowsMultipleSelection = false
		panel.message = "Select a Chronicle database directory (contains history.db)"
		panel.prompt = "Open"

		guard panel.runModal() == .OK, let url = panel.url else { return }
		openDatabase(at: url)
	}

	private func openDatabase(at directoryURL: URL) {
		let dbURL = directoryURL.appendingPathComponent("history.db")
		guard FileManager.default.fileExists(atPath: dbURL.path) else {
			errorMessage = "No history.db found in \(directoryURL.lastPathComponent)"
			return
		}

		do {
			var config = ChronicleConfiguration(isReadOnly: true)
			config.databaseLocation = directoryURL.deletingLastPathComponent()
			try Chronicle.instance.configure(config)

			guard let container = Chronicle.instance.modelContainer else {
				errorMessage = "Failed to configure Chronicle"
				return
			}

			withAnimation {
				self.selectedURL = directoryURL
				self.watcher = DatabaseWatcher(dbURL: dbURL, modelContainer: container)
				self.model = ChronicleViewerModel()
				self.errorMessage = nil
			}
		} catch {
			errorMessage = "Failed to open database: \(error.localizedDescription)"
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

	var body: some View {
		Group {
			if let model {
				ChronicleTabContent(model: model, showClearConfirmation: $showClearConfirmation, currentRunOnly: false)
					.modelContainer(model.modelContainer)
			}
		}
		.onChange(of: watcher.refreshToken) {
			refresh()
		}
	}

	private func refresh() {
		do {
			var config = ChronicleConfiguration(isReadOnly: true)
			config.databaseLocation = directoryURL.deletingLastPathComponent()
			try Chronicle.instance.configure(config)
			model = ChronicleViewerModel()
		} catch {}
	}
}
