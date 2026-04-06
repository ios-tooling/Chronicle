import Foundation
import SwiftData
import TagAlong

// MARK: - Persisted CloudKit Log

@available(iOS 17, macOS 14, *)
@Model
final class PersistedCloudKitLog {
	@Attribute(.unique) var entryID: UUID
	var timestamp: Date
	var direction: String
	var recordName: String
	var recordType: String
	var zoneName: String
	var zoneOwner: String?
	var recordSize: Int?
	var fieldCount: Int?
	var duration: Double?
	var errorMessage: String?
	var contextJSON: Data?
	var tagsJSON: Data?
	var referenceURLString: String?
	var referenceID: String?
	var sourceFile: String?
	var sourceFunction: String?
	var sourceLine: Int?

	init(
		entryID: UUID,
		timestamp: Date,
		direction: String,
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String?,
		recordSize: Int?,
		fieldCount: Int?,
		duration: Double?,
		errorMessage: String?,
		contextJSON: Data?,
		tagsJSON: Data?,
		referenceURLString: String?,
		referenceID: String?,
		sourceFile: String?,
		sourceFunction: String?,
		sourceLine: Int?
	) {
		self.entryID = entryID
		self.timestamp = timestamp
		self.direction = direction
		self.recordName = recordName
		self.recordType = recordType
		self.zoneName = zoneName
		self.zoneOwner = zoneOwner
		self.recordSize = recordSize
		self.fieldCount = fieldCount
		self.duration = duration
		self.errorMessage = errorMessage
		self.contextJSON = contextJSON
		self.tagsJSON = tagsJSON
		self.referenceURLString = referenceURLString
		self.referenceID = referenceID
		self.sourceFile = sourceFile
		self.sourceFunction = sourceFunction
		self.sourceLine = sourceLine
	}

	func toCloudKitLog() -> CloudKitLog {
		let context = contextJSON.flatMap { try? JSONDecoder().decode(EventMetadata.self, from: $0) }
		let tags = tagsJSON.flatMap { try? JSONDecoder().decode([Tag].self, from: $0) }
		let refURL = referenceURLString.flatMap { URL(string: $0) }
		return CloudKitLog(
			id: entryID,
			timestamp: timestamp,
			operation: CloudKitOperation(rawValue: direction) ?? .download,
			recordName: recordName,
			recordType: recordType,
			zoneName: zoneName,
			zoneOwner: zoneOwner,
			recordSize: recordSize,
			fieldCount: fieldCount,
			duration: duration,
			error: errorMessage,
			context: context,
			tags: tags,
			referenceURL: refURL,
			referenceID: referenceID,
			sourceFile: sourceFile,
			sourceFunction: sourceFunction,
			sourceLine: sourceLine
		)
	}

	static func from(_ log: CloudKitLog) -> PersistedCloudKitLog {
		let contextJSON = log.context.flatMap { try? JSONEncoder().encode($0) }
		let tagsJSON = log.tags.flatMap { try? JSONEncoder().encode($0) }
		return PersistedCloudKitLog(
			entryID: log.id,
			timestamp: log.timestamp,
			direction: log.operation.rawValue,
			recordName: log.recordName,
			recordType: log.recordType,
			zoneName: log.zoneName,
			zoneOwner: log.zoneOwner,
			recordSize: log.recordSize,
			fieldCount: log.fieldCount,
			duration: log.duration,
			errorMessage: log.error,
			contextJSON: contextJSON,
			tagsJSON: tagsJSON,
			referenceURLString: log.referenceURL?.absoluteString,
			referenceID: log.referenceID,
			sourceFile: log.sourceFile,
			sourceFunction: log.sourceFunction,
			sourceLine: log.sourceLine
		)
	}
}
