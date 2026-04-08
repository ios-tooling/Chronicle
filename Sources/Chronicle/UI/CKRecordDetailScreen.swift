import SwiftUI
import CloudKit

/// Shows all fields of a cached CKRecord with a button to remove it from the cache.
@available(iOS 17, macOS 14, *)
struct CKRecordDetailScreen: View {
	let entryID: UUID
	let log: CloudKitLog
	@State private var record: CKRecord?
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		Group {
			if let record {
				recordContent(record)
			} else {
				ContentUnavailableView("Record Removed", systemImage: "tray")
			}
		}
		.navigationTitle(log.recordType)
		#if !os(macOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
		.onAppear { record = Chronicle.instance.cloudKit?.recordCache?.record(for: entryID) }
	}

	private func recordContent(_ record: CKRecord) -> some View {
		List {
			Section("Record Info") {
				row("Record Name", record.recordID.recordName)
				row("Record Type", record.recordType)
				row("Zone", record.recordID.zoneID.zoneName)
				if let modified = record.modificationDate {
					row("Modified", modified.chronicle_formatted)
				}
				if let created = record.creationDate {
					row("Created", created.chronicle_formatted)
				}
			}

			Section("Fields") {
				ForEach(record.allKeys().sorted(), id: \.self) { key in
					fieldRow(key: key, value: record[key])
				}
			}

			Section {
				Button(role: .destructive) { removeFromCache() } label: {
					Label("Remove from Cache", systemImage: "trash")
				}
			}
		}
	}

	private func fieldRow(key: String, value: (any CKRecordValueProtocol)?) -> some View {
		HStack(alignment: .top) {
			Text(key)
				.font(.caption.monospaced())
				.foregroundStyle(.secondary)
			Spacer()
			Text(fieldDescription(value))
				.font(.caption.monospaced())
				.multilineTextAlignment(.trailing)
				.textSelection(.enabled)
		}
	}

	private func fieldDescription(_ value: (any CKRecordValueProtocol)?) -> String {
		guard let value else { return "nil" }
		switch value {
		case let string as String: return string
		case let number as NSNumber: return number.stringValue
		case let date as Date: return date.chronicle_formatted
		case let data as Data: return "\(data.count) bytes"
		case let asset as CKAsset: return asset.fileURL?.lastPathComponent ?? "asset"
		case let ref as CKRecord.Reference: return ref.recordID.recordName
		case let list as [String]: return list.joined(separator: ", ")
		case let location as CLLocation:
			return String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
		default: return String(describing: value)
		}
	}

	private func row(_ label: String, _ value: String) -> some View {
		HStack(alignment: .top) {
			Text(label).foregroundStyle(.secondary)
			Spacer()
			Text(value).textSelection(.enabled)
		}
	}

	private func removeFromCache() {
		Chronicle.instance.cloudKit?.recordCache?.remove(for: entryID)
		record = nil
	}
}
