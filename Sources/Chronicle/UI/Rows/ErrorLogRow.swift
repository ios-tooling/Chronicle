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
                ErrorBadge(text: error.severity.rawValue.uppercased(), color: severityColor)

					if showTags, let tags = error.tags { TagsView(tags: tags, onTap: tagTapAction) }

					Text(error.errorType)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

					Spacer()
					error.timestamp.timestampView
            }

            ErrorLogSummary(error: error)
        }
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
