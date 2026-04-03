import SwiftUI
#if canImport(WebKit)
import WebKit
#endif

/// A button that shows a truncated URL. File URLs reveal in Finder; web URLs open in a browser sheet.
@available(iOS 17, macOS 14, *)
struct EntryURLButton: View {
	let url: URL
	@State private var showWebSheet = false

	var body: some View {
		Button { handleTap() } label: {
			HStack(spacing: 3) {
				Image(systemName: url.isFileURL ? "folder" : "link")
					.font(.caption2)
				Text(displayString)
					.font(.caption2)
					.lineLimit(1)
			}
			.foregroundStyle(.blue)
		}
		.buttonStyle(.plain)
		.sheet(isPresented: $showWebSheet) {
			WebViewSheet(url: url)
		}
	}

	private var displayString: String {
		if url.isFileURL {
			return url.lastPathComponent
		}
		var display = url.host() ?? url.absoluteString
		if let path = url.path().nilIfEmpty, path != "/" {
			display += path
		}
		if display.count > 40 {
			return String(display.prefix(37)) + "…"
		}
		return display
	}

	private func handleTap() {
		#if os(macOS)
		if url.isFileURL {
			NSWorkspace.shared.activateFileViewerSelecting([url])
		} else {
			showWebSheet = true
		}
		#else
		if url.isFileURL {
			// No Finder on iOS — just open
			return
		}
		showWebSheet = true
		#endif
	}
}

@available(iOS 17, macOS 14, *)
private struct WebViewSheet: View {
	let url: URL
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			WebViewRepresentable(url: url)
				.navigationTitle(url.host() ?? "Web")
				#if !os(macOS)
				.navigationBarTitleDisplayMode(.inline)
				#endif
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button("Done") { dismiss() }
					}
					ToolbarItem(placement: .primaryAction) {
						Button { openInSafari() } label: {
							Label("Open in Safari", systemImage: "safari")
						}
					}
				}
		}
		#if os(macOS)
		.frame(minWidth: 600, minHeight: 400)
		#endif
	}

	private func openInSafari() {
		#if os(macOS)
		NSWorkspace.shared.open(url)
		#else
		UIApplication.shared.open(url)
		#endif
	}
}

#if canImport(WebKit)
@available(iOS 17, macOS 14, *)
private struct WebViewRepresentable {
	let url: URL
}

#if os(macOS)
@available(iOS 17, macOS 14, *)
extension WebViewRepresentable: NSViewRepresentable {
	func makeNSView(context: Context) -> WKWebView {
		let webView = WKWebView()
		webView.load(URLRequest(url: url))
		return webView
	}
	func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#else
@available(iOS 17, macOS 14, *)
extension WebViewRepresentable: UIViewRepresentable {
	func makeUIView(context: Context) -> WKWebView {
		let webView = WKWebView()
		webView.load(URLRequest(url: url))
		return webView
	}
	func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#endif
#endif

private extension String {
	var nilIfEmpty: String? { isEmpty ? nil : self }
}
