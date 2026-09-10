import SwiftUI

/// The message and context lines of an error, shared by the error row and a failed request's row.
@available(iOS 17, macOS 14, *)
struct ErrorLogSummary: View {
    let error: ErrorLog

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
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
        guard let value = error.context?["context"] else { return nil }
        return "\(value)"
    }
}

/// A small tinted pill for an error's severity or type. It never truncates; neighbors yield instead.
@available(iOS 17, macOS 14, *)
struct ErrorBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
            .fixedSize()
    }
}
