import Foundation
import SwiftData
import TagAlong

// MARK: - Persisted Generic Entry

@available(iOS 17, macOS 14, *)
@Model
final class PersistedGenericEntry {
    @Attribute(.unique) var entryID: UUID
    var timestamp: Date
    var category: String
    var summary: String
    var payloadJSON: Data
    var tagsJSON: Data?
    var sourceFile: String?
    var sourceFunction: String?
    var sourceLine: Int?

    init(entryID: UUID, timestamp: Date, category: String, summary: String, payloadJSON: Data, tagsJSON: Data?, sourceFile: String?, sourceFunction: String?, sourceLine: Int?) {
        self.entryID = entryID
        self.timestamp = timestamp
        self.category = category
        self.summary = summary
        self.payloadJSON = payloadJSON
        self.tagsJSON = tagsJSON
        self.sourceFile = sourceFile
        self.sourceFunction = sourceFunction
        self.sourceLine = sourceLine
    }

    func toGenericEntry() -> GenericChronicleEntry {
        let tags = tagsJSON.flatMap { try? JSONDecoder().decode([Tag].self, from: $0) }
        return GenericChronicleEntry(id: entryID, timestamp: timestamp, category: EntryCategory(category), summary: summary, payload: payloadJSON, tags: tags, sourceFile: sourceFile, sourceFunction: sourceFunction, sourceLine: sourceLine)
    }

    static func from(_ entry: any ChronicleEntry) -> PersistedGenericEntry? {
        guard let payload = try? JSONEncoder().encode(entry) else { return nil }
        let tagsJSON = entry.tags.flatMap { try? JSONEncoder().encode($0) }
        return PersistedGenericEntry(
            entryID: entry.id,
            timestamp: entry.timestamp,
            category: entry.category.rawValue,
            summary: entry.displaySummary,
            payloadJSON: payload,
            tagsJSON: tagsJSON,
            sourceFile: entry.sourceFile,
            sourceFunction: entry.sourceFunction,
            sourceLine: entry.sourceLine
        )
    }
}
