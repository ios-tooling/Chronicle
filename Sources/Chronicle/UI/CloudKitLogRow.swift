import SwiftUI

/// Row view for a CloudKitLog entry.
@available(iOS 17, macOS 14, *)
struct CloudKitLogRow: View {
	let log: CloudKitLog

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack(spacing: 6) {
				Image(systemName: log.direction == .upload ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
					.foregroundStyle(log.direction == .upload ? .orange : .blue)

				Text(log.recordType)
					.font(.subheadline.weight(.medium))
					.lineLimit(1)

				Spacer()

				if log.error != nil {
					Label("Error", systemImage: "xmark.circle.fill")
						.font(.caption)
						.foregroundStyle(.red)
				}
			}

			HStack(spacing: 8) {
				Text(log.recordName)
					.font(.caption.monospaced())
					.lineLimit(1)
					.foregroundStyle(.secondary)

				Spacer()

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
}
