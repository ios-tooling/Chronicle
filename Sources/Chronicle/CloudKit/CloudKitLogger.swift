import Foundation
import CloudKit
import TagAlong

/// Logs CloudKit record uploads, downloads, and deletions.
@available(iOS 17, macOS 14, *)
public final class CloudKitLogger: @unchecked Sendable {
	private let storage: SwiftDataStorage
	private var _recordCache: CKRecordCache?

	init(storage: SwiftDataStorage) {
		self.storage = storage
	}

	/// The CKRecord cache, if enabled via `setCloudKitCacheSize(_:)`.
	public var recordCache: CKRecordCache? { _recordCache }

	/// Enables caching of CKRecords. Pass 0 to disable.
	public func setCacheSize(_ maxRecords: Int) {
		if maxRecords > 0 {
			if let cache = _recordCache {
				cache.cacheSize = maxRecords
			} else {
				_recordCache = CKRecordCache(maxSize: maxRecords)
			}
		} else {
			_recordCache?.cacheSize = 0
			_recordCache = nil
		}
	}

	/// Log a CloudKit record upload.
	public func logUpload(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		record: CKRecord? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let log = CloudKitLog(
			operation: .upload,
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function, sourceLine: line
		)
		storage.store(log)
		if let record { _recordCache?.store(record, for: log.id) }
	}

	/// Log a CloudKit record download.
	public func logDownload(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		recordSize: Int? = nil,
		fieldCount: Int? = nil,
		duration: TimeInterval? = nil,
		error: String? = nil,
		record: CKRecord? = nil,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let log = CloudKitLog(
			operation: .download,
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			recordSize: recordSize, fieldCount: fieldCount,
			duration: duration, error: error, tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function, sourceLine: line
		)
		storage.store(log)
		if let record { _recordCache?.store(record, for: log.id) }
	}

	/// Log a CloudKit record deletion.
	public func logDeletion(
		recordName: String,
		recordType: String,
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let log = CloudKitLog(
			operation: .deleted,
			recordName: recordName, recordType: recordType,
			zoneName: zoneName, zoneOwner: zoneOwner,
			tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function, sourceLine: line
		)
		storage.store(log)
	}

	/// Log a CloudKit zone creation.
	public func logZoneCreated(
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let log = CloudKitLog(
			operation: .zoneCreated,
			recordName: "", recordType: "",
			zoneName: zoneName, zoneOwner: zoneOwner,
			tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function, sourceLine: line
		)
		storage.store(log)
	}

	/// Log a CloudKit zone creation from a zone ID.
	public func logZoneCreated(
		zoneID: CKRecordZone.ID,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		logZoneCreated(zoneName: zoneID.zoneName, zoneOwner: zoneID.ownerName, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}

	/// Log a CloudKit zone deletion.
	public func logZoneDeleted(
		zoneName: String,
		zoneOwner: String = "_defaultOwner",
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let log = CloudKitLog(
			operation: .zoneDeleted,
			recordName: "", recordType: "",
			zoneName: zoneName, zoneOwner: zoneOwner,
			tags: tags,
			referenceURL: referenceURL, referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function, sourceLine: line
		)
		storage.store(log)
	}

	/// Log a CloudKit zone deletion from a zone ID.
	public func logZoneDeleted(
		zoneID: CKRecordZone.ID,
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		logZoneDeleted(zoneName: zoneID.zoneName, zoneOwner: zoneID.ownerName, tags: tags, referenceURL: referenceURL, referenceID: referenceID, file: file, function: function, line: line)
	}

	/// Log a pre-built CloudKitLog entry directly, optionally caching the associated record.
	public func log(_ cloudKitLog: CloudKitLog, record: CKRecord? = nil) {
		storage.store(cloudKitLog)
		if let record { _recordCache?.store(record, for: cloudKitLog.id) }
	}

	private static let allCloudKitCategories: Set<EntryCategory> = [.cloudKitUpload, .cloudKitDownload, .cloudKitDelete]

	/// Returns recent CloudKit logs.
	public func recentLogs(limit: Int = 100) -> [CloudKitLog] {
		let query = StorageQuery(categories: Self.allCloudKitCategories, limit: limit)
		return storage.entries(matching: query).compactMap { $0 as? CloudKitLog }
	}

	/// Returns all stored CloudKit logs.
	public func allLogs() -> [CloudKitLog] {
		let query = StorageQuery(categories: Self.allCloudKitCategories)
		return storage.entries(matching: query).compactMap { $0 as? CloudKitLog }
	}
}
