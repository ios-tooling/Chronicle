import SwiftUI
import TagAlong

/// Row view for a CloudKitLog entry.
@available(iOS 17, macOS 14, *)
struct CloudKitLogRow: View {
	let log: CloudKitLog
	@Environment(\.showTags) private var showTags
	@Environment(\.tagTapAction) private var tagTapAction

	private var isZoneEvent: Bool {
		log.operation == .zoneCreated || log.operation == .zoneDeleted
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack(spacing: 6) {
				if showTags, let tags = log.tags { TagsView(tags: tags, onTap: tagTapAction) }

				if isZoneEvent {
					Text(log.operation == .zoneCreated ? "Zone Created" : "Zone Deleted")
						.font(.subheadline.weight(.medium))
				} else {
					Text(log.recordType)
						.font(.subheadline.weight(.medium))
						.lineLimit(1)
				}

				Spacer()

				if log.error != nil {
					Label("Error", systemImage: "xmark.circle.fill")
						.font(.caption)
						.foregroundStyle(.red)
				}
			}

			HStack(spacing: 8) {
				if isZoneEvent {
					Text(zoneDisplay)
						.font(.caption.monospaced())
						.lineLimit(1)
						.foregroundStyle(.secondary)
				} else {
					Text(log.recordName)
						.font(.caption.monospaced())
						.lineLimit(1)
						.foregroundStyle(.secondary)
				}

				Spacer()

				if !isZoneEvent, !log.zoneName.isEmpty {
					Text(log.zoneName)
						.font(.caption2)
						.foregroundStyle(.tertiary)
						.lineLimit(1)
				}

				if let size = log.recordSize {
					Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
						.font(.caption.monospaced())
				}

				if let duration = log.duration {
					HStack(spacing: 2) {
						Image(systemName: "clock")
							.font(.caption2)
						Text(String(format: "%.0fms", duration * 1000))
							.font(.caption.monospaced())
					}
					.foregroundStyle(.secondary)
				}

				log.timestamp.timestampView
			}
		}
	}

	private var zoneDisplay: String {
		if log.zoneOwner != "_defaultOwner" && !log.zoneOwner.isEmpty {
			return "\(log.zoneName) (\(log.zoneOwner))"
		}
		return log.zoneName
	}
}
