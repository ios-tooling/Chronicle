import SwiftUI
import TagAlong

/// Detail screen showing full information for a tracked event.
@available(iOS 17, macOS 14, *)
struct EventDetailScreen: View {
	let event: Event

	var body: some View {
		List {
			overviewSection
			if let context = event.context, !context.isEmpty { contextSection(context) }
			if let tags = event.tags, !tags.isEmpty { tagsSection(tags) }
			if event.referenceURL != nil || event.referenceID != nil { referenceSection }
			if event.sourceFile != nil || event.sourceFunction != nil { sourceSection }
		}
		.navigationTitle("Event Detail")
		#if !os(macOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
	}

	private var overviewSection: some View {
		Section("Overview") {
			row("Name", event.name)
			row("Timestamp", event.timestamp.chronicle_formatted)
			row("ID", event.id.uuidString)
		}
	}

	private func contextSection(_ context: EventMetadata) -> some View {
		Section("Context") {
			ForEach(context.dictionary.keys.sorted(), id: \.self) { key in
				row(key, "\(context.dictionary[key]!)")
			}
		}
	}

	private func tagsSection(_ tags: [Tag]) -> some View {
		Section("Tags") {
			TagsView(tags: tags)
		}
	}

	@ViewBuilder
	private var referenceSection: some View {
		Section("Reference") {
			if let id = event.referenceID { row("ID", id) }
			if let url = event.referenceURL {
				HStack {
					Text("URL").foregroundStyle(.secondary)
					Spacer()
					EntryURLButton(url: url)
				}
			}
		}
	}

	@ViewBuilder
	private var sourceSection: some View {
		Section("Source") {
			if let file = event.sourceFile, let line = event.sourceLine {
				monoRow("Location", "\(file):\(line)")
			}
			if let function = event.sourceFunction {
				monoRow("Function", function)
			}
		}
	}

	private func row(_ label: String, _ value: String) -> some View {
		HStack(alignment: .top) {
			Text(label).foregroundStyle(.secondary)
			Spacer()
			Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
		}
	}

	private func monoRow(_ label: String, _ value: String) -> some View {
		HStack(alignment: .top) {
			Text(label).foregroundStyle(.secondary)
			Spacer()
			Text(value).font(.footnote.monospaced()).multilineTextAlignment(.trailing).textSelection(.enabled)
		}
	}
}
