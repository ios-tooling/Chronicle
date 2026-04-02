import SwiftUI

/// Row view for an ErrorLog entry.
@available(iOS 17, macOS 14, *)
struct ErrorLogRow: View {
    let error: ErrorLog
    @Environment(\.showTags) private var showTags
    @Environment(\.tagTapAction) private var tagTapAction

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(error.severity.rawValue.uppercased())
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(severityColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(severityColor)

					if showTags, let tags = error.tags { TagsView(tags: tags, onTap: tagTapAction) }

					Text(error.errorType)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
					
					Spacer()
					error.timestamp.timestampView
            }

            Text(error.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let context = contextString {
                Text(context)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var contextString: String? {
        guard let ctx = error.context, let value = ctx["context"] else { return nil }
        return "\(value)"
    }

    private var severityColor: Color {
        switch error.severity {
        case .critical: .red
        case .error: .red
        case .warning: .yellow
        case .info: .blue
        case .debug: .secondary
        }
    }
}
