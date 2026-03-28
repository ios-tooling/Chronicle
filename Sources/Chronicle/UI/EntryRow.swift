import SwiftUI
import TagAlong

/// Dispatches to the appropriate row view based on entry type.
@available(iOS 17, macOS 14, *)
struct EntryRow: View {
    let entry: any ChronicleEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.category.systemImage)
                .foregroundStyle(entry.category.tintColor)
                .frame(width: 24)

			  VStack(alignment: .leading, spacing: 4) {
                entryContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var entryContent: some View {
        switch entry {
        case let event as Event: EventRow(event: event)
		  case let log as NetworkLog: NetworkLogRow(log: log)
        case let flow as FlowEvent: FlowEventRow(flow: flow)
        case let error as ErrorLog: ErrorLogRow(error: error)
        case let ck as CloudKitLog: CloudKitLogRow(log: ck)
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

@available(iOS 17, macOS 14, *)
extension Date {
	var formattedTimestamp: String {
		 if Calendar.current.isDateInToday(self) {
			  return self.chronicle_timeOnly
		 }
		 return self.chronicle_formatted
	}
	
	var timestampView: some View {
		Text(self.formattedTimestamp)
			  .font(.caption2)
			  .foregroundStyle(.secondary)
			  .monospacedDigit()
	}
}
