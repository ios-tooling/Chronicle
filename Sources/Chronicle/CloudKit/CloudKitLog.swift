import Foundation
import TagAlong

/// The type of CloudKit record operation.
public enum CloudKitOperation: String, Codable, Sendable, Hashable {
	case upload
	case download
	case deleted
	case zoneCreated
	case zoneDeleted
}

/// Represents a logged CloudKit record operation.
public struct CloudKitLog: ChronicleEntry {
	public let id: UUID
	public let timestamp: Date
	public var category: EntryCategory {
		switch operation {
		case .upload: .cloudKitUpload
		case .download: .cloudKitDownload
		case .deleted: .cloudKitDelete
		case .zoneDeleted: .cloudKitZoneDeleted
		case .zoneCreated: .cloudKitZoneCreated
		}
	}

	/// The type of operation performed.
	public let operation: CloudKitOperation

	/// The CKRecord.ID recordName.
	public let recordName: String

	/// The record type (e.g. "CD_MyEntity").
	public let recordType: String

	/// The zone name from the CKRecordZone.ID.
	public let zoneName: String

	/// The zone owner from the CKRecordZone.ID.
	public let zoneOwner: String

	/// Overall size of the record in bytes.
	public let recordSize: Int?

	/// Number of fields in the record.
	public let fieldCount: Int?

	/// Duration of the operation in seconds.
	public let duration: TimeInterval?

	/// Error description if the operation failed.
	public let error: String?

	/// Optional context about this CloudKit operation.
	public let context: EventMetadata?

	public let tags: [Tag]?
	public let referenceURL: URL?
	public let referenceID: String?
	public let sourceFile: String?
	public let sourceFunction: String?
	public let sourceLine: Int?

	public var displaySummary: String {
		switch operation {
		case .upload: "up \(recordType) — \(recordName)"
		case .download: "down \(recordType) — \(recordName)"
		case .deleted: "del \(recordType) — \(recordName)"
		case .zoneCreated: "zone created — \(zoneName)"
		case .zoneDeleted: "zone deleted — \(zoneName)"
		}
	}

	public func matches(filter: String) -> Bool {
		recordName.localizedCaseInsensitiveContains(filter)
		|| recordType.localizedCaseInsensitiveContains(filter)
		|| zoneName.localizedCaseInsensitiveContains(filter)
	}

	public init(
		id: UUID = UUID(),
		timestamp: Date = Date(),
		operation: CloudKitOperation,
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		context: EventMetadata? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		sourceFile: String? = nil,
		sourceFunction: String? = nil,
		sourceLine: Int? = nil
	) {
		self.id = id
		self.timestamp = timestamp
		self.operation = operation
		self.recordName = recordName
		self.recordType = recordType
		self.zoneName = zoneName
		self.zoneOwner = zoneOwner
		self.recordSize = recordSize
		self.fieldCount = fieldCount
		self.duration = duration
		self.error = error
		self.context = context
		self.tags = tags?.tags
		self.referenceURL = referenceURL
		self.referenceID = referenceID
		self.sourceFile = sourceFile
		self.sourceFunction = sourceFunction
		self.sourceLine = sourceLine
	}
}
