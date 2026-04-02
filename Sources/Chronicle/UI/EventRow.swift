import SwiftUI
import TagAlong

/// Row view for an Event entry.
@available(iOS 17, macOS 14, *)
struct EventRow: View {
	let event: Event
	@Environment(\.showTags) private var showTags
	@Environment(\.tagTapAction) private var tagTapAction

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack {
				if showTags, let tags = event.tags { TagsView(tags: tags, onTap: tagTapAction) }

				Text(event.name)
					.font(.subheadline.weight(.medium))
					.lineLimit(1)
				Spacer()
				event.timestamp.timestampView
			}
			
			if let metadata = event.metadata, !metadata.isEmpty {
				Text(metadataSummary(metadata))
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}
		}
	}
	
	private func metadataSummary(_ metadata: EventMetadata) -> String {
		metadata.dictionary.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
	}
}
