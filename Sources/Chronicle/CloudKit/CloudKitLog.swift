import Foundation
import TagAlong

/// The direction of a CloudKit record transfer.
public enum CloudKitDirection: String, Codable, Sendable, Hashable {
	case upload
	case download
}

/// Represents a logged CloudKit record upload or download.
public struct CloudKitLog: ChronicleEntry {
	public let id: UUID
	public let timestamp: Date
	public var category: EntryCategory { direction == .upload ? .cloudKitUpload : .cloudKitDownload }

	/// Whether this was an upload or download.
	public let direction: CloudKitDirection

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

	public let tags: [Tag]?
	public let referenceURL: URL?
	public let referenceID: String?
	public let sourceFile: String?
	public let sourceFunction: String?
	public let sourceLine: Int?

	public var displaySummary: String {
		let arrow = direction == .upload ? "up" : "down"
		return "\(arrow) \(recordType) — \(recordName)"
	}

	public func matches(filter: String) -> Bool {
		recordName.localizedCaseInsensitiveContains(filter)
		|| recordType.localizedCaseInsensitiveContains(filter)
		|| zoneName.localizedCaseInsensitiveContains(filter)
	}

	public init(
		id: UUID = UUID(),
		timestamp: Date = Date(),
		direction: CloudKitDirection,
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		sourceFile: String? = nil,
		sourceFunction: String? = nil,
		sourceLine: Int? = nil
	) {
		self.id = id
		self.timestamp = timestamp
		self.direction = direction
		self.recordName = recordName
		self.recordType = recordType
		self.zoneName = zoneName
		self.zoneOwner = zoneOwner
		self.recordSize = recordSize
		self.fieldCount = fieldCount
		self.duration = duration
		self.error = error
		self.tags = tags?.tags
		self.referenceURL = referenceURL
		self.referenceID = referenceID
		self.sourceFile = sourceFile
		self.sourceFunction = sourceFunction
		self.sourceLine = sourceLine
	}
}
