import Foundation
import CloudKit
import os

/// A FIFO disk-backed cache for CKRecord objects, keyed by Chronicle entry UUID.
@available(iOS 17, macOS 14, *)
public final class CKRecordCache: @unchecked Sendable {
	private let lock = OSAllocatedUnfairLock()
	private var maxSize: Int
	private var manifest: [Entry]
	private let directory: URL
	private let manifestURL: URL

	struct Entry: Codable {
		let entryID: UUID
		let timestamp: Date
	}

	init(maxSize: Int) {
		self.maxSize = maxSize
		let dir = URL.cachesDirectory.appendingPathComponent("com.chronicle.ckrecords")
		try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
		self.directory = dir
		self.manifestURL = dir.appendingPathComponent("manifest.json")
		self.manifest = (try? JSONDecoder().decode([Entry].self, from: Data(contentsOf: manifestURL))) ?? []
	}

	/// The current maximum number of cached records. Setting to 0 disables caching and clears the cache.
	public var cacheSize: Int {
		get { lock.withLock { maxSize } }
		set {
			lock.withLock {
				maxSize = newValue
				if newValue == 0 { clearAll() }
				else { evict() }
			}
		}
	}

	/// Stores a CKRecord associated with a Chronicle entry ID.
	func store(_ record: CKRecord, for entryID: UUID) {
		lock.withLock {
			guard maxSize > 0 else { return }
			guard let data = try? NSKeyedArchiver.archivedData(withRootObject: record, requiringSecureCoding: true) else { return }
			try? data.write(to: fileURL(for: entryID))
			manifest.removeAll { $0.entryID == entryID }
			manifest.append(Entry(entryID: entryID, timestamp: Date()))
			evict()
			saveManifest()
		}
	}

	/// Retrieves a cached CKRecord for the given entry ID.
	public func record(for entryID: UUID) -> CKRecord? {
		lock.withLock {
			guard let data = try? Data(contentsOf: fileURL(for: entryID)) else { return nil }
			return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.self, from: data)
		}
	}

	/// Whether a cached record exists for the given entry ID.
	public func hasRecord(for entryID: UUID) -> Bool {
		lock.withLock {
			FileManager.default.fileExists(atPath: fileURL(for: entryID).path)
		}
	}

	/// Removes a cached record for the given entry ID.
	public func remove(for entryID: UUID) {
		lock.withLock {
			try? FileManager.default.removeItem(at: fileURL(for: entryID))
			manifest.removeAll { $0.entryID == entryID }
			saveManifest()
		}
	}

	/// Removes all cached records.
	public func clearAll() {
		for entry in manifest {
			try? FileManager.default.removeItem(at: fileURL(for: entry.entryID))
		}
		manifest.removeAll()
		saveManifest()
	}

	private func fileURL(for entryID: UUID) -> URL {
		directory.appendingPathComponent("\(entryID.uuidString).ckrecord")
	}

	/// Evicts oldest entries until count <= maxSize. Must be called under lock.
	private func evict() {
		while manifest.count > maxSize {
			let oldest = manifest.removeFirst()
			try? FileManager.default.removeItem(at: fileURL(for: oldest.entryID))
		}
	}

	private func saveManifest() {
		try? JSONEncoder().encode(manifest).write(to: manifestURL)
	}
}
