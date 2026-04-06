import SwiftUI
import Chronicle
import SwiftData

struct ContentView: View {
	@State var selectedURL: URL?
	@State var watcher: DatabaseWatcher?
	@State var model: ChronicleViewerModel?
	@State var showClearConfirmation = false
	@State var errorMessage: String?
	@State var isRefreshing = false
	@State var securityScopedURL: URL?
	@AppStorage("lastDatabaseBookmark") var lastDatabaseBookmark: Data = Data()

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
}
