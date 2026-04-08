import Foundation
import CloudKit
import TagAlong

@available(iOS 17, macOS 14, *)
extension Chronicle {
	/// Logs a CloudKit record upload.
	nonisolated public static func cloudKitUpload(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		record: CKRecord? = nil,
		description: String? = nil,
		context: EventMetadata? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let merged = mergeDescription(description, into: context)
		instance.cloudKit?.logUpload(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, record: record, context: merged, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit record download.
	nonisolated public static func cloudKitDownload(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		record: CKRecord? = nil,
		description: String? = nil,
		context: EventMetadata? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let merged = mergeDescription(description, into: context)
		instance.cloudKit?.logDownload(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, record: record, context: merged, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit record deletion.
	nonisolated public static func cloudKitDelete(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		description: String? = nil,
		context: EventMetadata? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let merged = mergeDescription(description, into: context)
		instance.cloudKit?.logDeletion(
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			context: merged, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			file: file, function: function, line: line
		)
	}

	/// Logs a CloudKit zone creation.
	nonisolated public static func cloudKitZoneCreated(zoneName: String, zoneOwner: String = "_defaultOwner", description: String? = nil, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.cloudKit?.logZoneCreated(zoneName: zoneName, zoneOwner: zoneOwner, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}

	/// Logs a CloudKit zone creation from a zone ID.
	nonisolated public static func cloudKitZoneCreated(zoneID: CKRecordZone.ID, description: String? = nil, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.cloudKit?.logZoneCreated(zoneID: zoneID, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}

	/// Logs a CloudKit zone deletion.
	nonisolated public static func cloudKitZoneDeleted(zoneName: String, zoneOwner: String = "_defaultOwner", description: String? = nil, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.cloudKit?.logZoneDeleted(zoneName: zoneName, zoneOwner: zoneOwner, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}

	/// Logs a CloudKit zone deletion from a zone ID.
	nonisolated public static func cloudKitZoneDeleted(zoneID: CKRecordZone.ID, description: String? = nil, context: EventMetadata? = nil, tags: TagCollection? = nil, referenceURL: URL? = nil, referenceID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
		let merged = mergeDescription(description, into: context)
		instance.cloudKit?.logZoneDeleted(zoneID: zoneID, context: merged, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}
}
