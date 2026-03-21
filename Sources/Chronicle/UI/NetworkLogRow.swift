import SwiftUI

/// Row view for a NetworkLog entry.
struct NetworkLogRow: View {
    let log: NetworkLog

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(log.method)
                    .font(.caption.weight(.bold).monospaced())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))

                Text(log.url.path())
                    .font(.subheadline)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                if let status = log.statusCode {
                    Text("\(status)")
                        .font(.caption.weight(.semibold).monospaced())
                        .foregroundStyle(statusColor(status))
                }

                if let duration = log.metrics.duration {
                    Text(String(format: "%.0fms", duration * 1000))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                if log.error != nil {
                    Label("Error", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
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
