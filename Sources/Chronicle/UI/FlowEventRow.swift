import SwiftUI
import TagAlong

/// Row view for a FlowEvent entry.
@available(iOS 17, macOS 14, *)
struct FlowEventRow: View {
	let flow: FlowEvent
	@Environment(\.showTags) private var showTags

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack(spacing: 4) {
				if showTags, let tags = flow.tags { TagsView(tags: tags) }

				if let from = flow.from, from.screenName.caseInsensitiveCompare(flow.to.screenName) != .orderedSame {
					Text(from.screenName)
						.font(.subheadline)
						.foregroundStyle(.secondary)
					Image(systemName: "arrow.right")
						.font(.caption2)
						.foregroundStyle(.secondary)
					
				}
				Text(flow.to.screenName)
					.font(.subheadline.weight(.medium))
			}
			.lineLimit(1)
			
			HStack {
				if let meta = flow.to.additionalInfo {
					Text(meta.description)
				} else {
					Text(flow.transitionType.rawValue)
				}
				
				Spacer()
				flow.timestamp.timestampView
			}
			.font(.caption)
			.foregroundStyle(.secondary)
		}
	}
}
