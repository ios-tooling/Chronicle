import SwiftUI
import TagAlong

/// Row view for a NetworkLog entry.
@available(iOS 17, macOS 14, *)
struct NetworkLogRow: View {
    let log: NetworkLog
    @Environment(\.showTags) private var showTags
    @Environment(\.tagTapAction) private var tagTapAction

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(log.method)
                    .font(.caption.weight(.bold).monospaced())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))

					if showTags, let tags = log.tags { TagsView(tags: tags, onTap: tagTapAction) }

                Text(log.url.path())
                    .font(.subheadline)
                    .lineLimit(1)

					Spacer()

					if log.wasCancelled {
						OutcomeMarker(text: "Cancelled", systemImage: "nosign", color: .orange)
					} else if log.hasError {
						OutcomeMarker(text: "Error", systemImage: "xmark.circle.fill", color: .red)
					}
            }

            HStack(spacing: 8) {
                if let status = log.statusCode {
                    Text("\(status)")
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundStyle(statusColor(status))
                }

                if let size = log.responseBodySize {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                }

                if let duration = log.metrics.duration {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(String(format: "%.0fms", duration * 1000))
                            .font(.caption.monospaced())
                    }
                    .foregroundStyle(.secondary)
                }

					Spacer()
					log.timestamp.timestampView
            }

            if let linked = log.linkedError {
                ErrorBadge(text: linked.caseName ?? linked.errorType, color: .red)
                ErrorLogSummary(error: linked)
            }
        }
    }

    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: .green
        case 300..<400: .orange
        default: .red
        }
    }

}

/// A compact icon-and-word marker for how a request ended. A `Label` would inherit the list's
/// icon-aligning style and drift far from its text.
@available(iOS 17, macOS 14, *)
private struct OutcomeMarker: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(color)
    }
}
