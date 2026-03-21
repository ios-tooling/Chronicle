import SwiftUI

/// Row view for a FlowEvent entry.
struct FlowEventRow: View {
    let flow: FlowEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if let from = flow.from {
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

            Text(flow.transitionType.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
