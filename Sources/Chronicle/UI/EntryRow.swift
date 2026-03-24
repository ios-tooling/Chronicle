import SwiftUI

/// Dispatches to the appropriate row view based on entry type.
@available(iOS 17, macOS 14, *)
struct EntryRow: View {
    let entry: any ChronicleEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.category.systemImage)
                .foregroundStyle(entry.category.tintColor)
                .frame(width: 24)

            entryContent
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(Self.formatTimestamp(entry.timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private static func formatTimestamp(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(.dateTime.day().month().year(.twoDigits).hour().minute())
    }

    @ViewBuilder
    private var entryContent: some View {
        switch entry {
        case let event as Event: EventRow(event: event)
		  case let log as NetworkLog: NetworkLogRow(log: log)
        case let flow as FlowEvent: FlowEventRow(flow: flow)
        case let error as ErrorLog: ErrorLogRow(error: error)
        default:
            if let rowView = entry.category.style.rowView {
                rowView(entry)
            } else {
                Text(entry.displaySummary)
                    .font(.subheadline)
                    .lineLimit(2)
            }
        }
    }
}
