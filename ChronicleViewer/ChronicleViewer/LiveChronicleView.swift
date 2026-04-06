import SwiftUI
import SwiftData
import Chronicle

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
