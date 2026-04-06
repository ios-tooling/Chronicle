import Foundation
import SwiftData
import TagAlong

@available(iOS 17, macOS 14, *)
@Model
final class PersistedEvent {
    @Attribute(.unique) var entryID: UUID
    var timestamp: Date
    var name: String
    var contextJSON: Data?
    var tagsJSON: Data?
    var referenceURLString: String?
    var referenceID: String?
    var sourceFile: String?
    var sourceFunction: String?
    var sourceLine: Int?

    init(entryID: UUID, timestamp: Date, name: String, contextJSON: Data?, tagsJSON: Data?, referenceURLString: String?, referenceID: String?, sourceFile: String?, sourceFunction: String?, sourceLine: Int?) {
        self.entryID = entryID
        self.timestamp = timestamp
        self.name = name
        self.contextJSON = contextJSON
        self.tagsJSON = tagsJSON
        self.referenceURLString = referenceURLString
        self.referenceID = referenceID
        self.sourceFile = sourceFile
        self.sourceFunction = sourceFunction
        self.sourceLine = sourceLine
    }

    func toEvent() -> Event {
        var context: EventMetadata?
        if let data = contextJSON {
            context = try? JSONDecoder().decode(EventMetadata.self, from: data)
        }
        let tags = tagsJSON.flatMap { try? JSONDecoder().decode([Tag].self, from: $0) }
        let url = referenceURLString.flatMap { URL(string: $0) }
        return Event(id: entryID, timestamp: timestamp, name: name, context: context, tags: tags, referenceURL: url, referenceID: referenceID, sourceFile: sourceFile, sourceFunction: sourceFunction, sourceLine: sourceLine)
    }

    static func from(_ event: Event) -> PersistedEvent {
        let contextJSON = event.context.flatMap { try? JSONEncoder().encode($0) }
        let tagsJSON = event.tags.flatMap { try? JSONEncoder().encode($0) }
        return PersistedEvent(
            entryID: event.id, timestamp: event.timestamp, name: event.name,
            contextJSON: contextJSON, tagsJSON: tagsJSON,
            referenceURLString: event.referenceURL?.absoluteString, referenceID: event.referenceID,
            sourceFile: event.sourceFile, sourceFunction: event.sourceFunction, sourceLine: event.sourceLine
        )
    }
}
