import Foundation
import TagAlong

/// Logs CloudKit record uploads and downloads.
@available(iOS 17, macOS 14, *)
public final class CloudKitLogger: Sendable {
	private let storage: SwiftDataStorage

	init(storage: SwiftDataStorage) {
		self.storage = storage
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
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let log = CloudKitLog(
			direction: .upload,
			recordName: recordName,
			recordType: recordType,
			zoneName: zoneName,
			zoneOwner: zoneOwner,
			recordSize: recordSize,
			fieldCount: fieldCount,
			duration: duration,
			error: error,
			tags: tags,
			referenceURL: referenceURL,
			referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function,
			sourceLine: line
		)
		storage.store(log)
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
		tags: TagCollection? = nil,
		referenceURL: URL? = nil,
		referenceID: String? = nil,
		file: String = #file,
		function: String = #function,
		line: Int = #line
	) {
		let log = CloudKitLog(
			direction: .download,
			recordName: recordName,
			recordType: recordType,
			zoneName: zoneName,
			zoneOwner: zoneOwner,
			recordSize: recordSize,
			fieldCount: fieldCount,
			duration: duration,
			error: error,
			tags: tags,
			referenceURL: referenceURL,
			referenceID: referenceID,
			sourceFile: (file as NSString).lastPathComponent,
			sourceFunction: function,
			sourceLine: line
		)
		storage.store(log)
	}

	/// Log a pre-built CloudKitLog entry directly.
	public func log(_ cloudKitLog: CloudKitLog) {
		storage.store(cloudKitLog)
	}

	/// Returns recent CloudKit logs (both uploads and downloads).
	public func recentLogs(limit: Int = 100) -> [CloudKitLog] {
		let query = StorageQuery(categories: [.cloudKitUpload, .cloudKitDownload], limit: limit)
		return storage.entries(matching: query).compactMap { $0 as? CloudKitLog }
	}

	/// Returns all stored CloudKit logs.
	public func allLogs() -> [CloudKitLog] {
		let query = StorageQuery(categories: [.cloudKitUpload, .cloudKitDownload])
		return storage.entries(matching: query).compactMap { $0 as? CloudKitLog }
	}
}
