import SwiftUI

/// Row view for an Event entry.
struct EventRow: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

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
