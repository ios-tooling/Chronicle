import SwiftUI

/// Full-screen viewer for a data payload, with recursive JSON browsing.
@available(iOS 17, macOS 14, *)
struct DataBodyScreen: View {
	let title: String
	let data: Data
	@State private var showRaw = false
	
	var body: some View {
		Group {
			if showRaw {
				rawList
			} else if let json = parsedJSON {
				jsonList(json)
			} else if let text = String(data: data, encoding: .utf8) {
				List { Text(text).font(.footnote.monospaced()).textSelection(.enabled) }
			} else {
				List { Text("\(data.count) bytes (binary)").foregroundStyle(.secondary) }
			}
		}
		.navigationTitle(title)
#if !os(macOS)
		.navigationBarTitleDisplayMode(.inline)
#endif
		.toolbar {
			ToolbarItem(placement: .automatic) {
				Toggle(isOn: $showRaw) { Text("Raw") }
					.toggleStyle(.button)
			}
			
			#if targetEnvironment(simulator)
				ToolbarItem(placement: .automatic) {
					Button(action: {
						print(rawText)
					}) { Text("Log") }
						.toggleStyle(.button)
				}
			#endif
		}
	}

	var rawText: String {
		String(data: data, encoding: .utf8) ?? data.map { String(format: "%02x ", $0) }.joined()
	}
	
	private var rawList: some View {
		let lines = rawText.components(separatedBy: .newlines)
		return List(lines.indices, id: \.self) { i in
			Text(lines[i])
				.font(.footnote.monospaced())
				.textSelection(.enabled)
				.listRowSeparator(.hidden)
		}
		.listStyle(.plain)
	}
	
	private func jsonList(_ value: JSONValue) -> some View {
		List {
			JSONValueRows(value: value)
		}
		.listStyle(.plain)
	}
	
	private var parsedJSON: JSONValue? {
		guard let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
		return JSONValue(obj)
	}
}
