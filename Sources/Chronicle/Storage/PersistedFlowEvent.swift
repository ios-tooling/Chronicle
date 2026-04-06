import Foundation
import SwiftData
import TagAlong

// MARK: - Persisted Flow Event

@available(iOS 17, macOS 14, *)
@Model
final class PersistedFlowEvent {
    @Attribute(.unique) var entryID: UUID
    var timestamp: Date
    var fromScreenName: String?
    var fromTransitionType: String?
    var fromTimestamp: Date?
    var fromInfoJSON: Data?
    var toScreenName: String
    var toTransitionType: String
    var toTimestamp: Date
    var toInfoJSON: Data?
    var transitionType: String
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
        fromScreenName: String?,
        fromTransitionType: String?,
        fromTimestamp: Date?,
        fromInfoJSON: Data?,
        toScreenName: String,
        toTransitionType: String,
        toTimestamp: Date,
        toInfoJSON: Data?,
        transitionType: String,
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
        self.fromScreenName = fromScreenName
        self.fromTransitionType = fromTransitionType
        self.fromTimestamp = fromTimestamp
        self.fromInfoJSON = fromInfoJSON
        self.toScreenName = toScreenName
        self.toTransitionType = toTransitionType
        self.toTimestamp = toTimestamp
        self.toInfoJSON = toInfoJSON
        self.transitionType = transitionType
        self.contextJSON = contextJSON
        self.tagsJSON = tagsJSON
        self.referenceURLString = referenceURLString
        self.referenceID = referenceID
        self.sourceFile = sourceFile
        self.sourceFunction = sourceFunction
        self.sourceLine = sourceLine
    }

    func toFlowEvent() -> FlowEvent {
        let decoder = JSONDecoder()
        var fromStep: FlowStep?
        if let fromName = fromScreenName,
           let fromType = fromTransitionType.flatMap({ TransitionType(rawValue: $0) }),
           let fromTime = fromTimestamp {
            let fromInfo = fromInfoJSON.flatMap { try? decoder.decode(EventMetadata.self, from: $0) }
            fromStep = FlowStep(
                screenName: fromName,
                transitionType: fromType,
                timestamp: fromTime,
                additionalInfo: fromInfo
            )
        }
        let toInfo = toInfoJSON.flatMap { try? decoder.decode(EventMetadata.self, from: $0) }
        let toStep = FlowStep(
            screenName: toScreenName,
            transitionType: TransitionType(rawValue: toTransitionType) ?? .push,
            timestamp: toTimestamp,
            additionalInfo: toInfo
        )
        let context = contextJSON.flatMap { try? JSONDecoder().decode(EventMetadata.self, from: $0) }
        let tags = tagsJSON.flatMap { try? JSONDecoder().decode([Tag].self, from: $0) }
        let refURL = referenceURLString.flatMap { URL(string: $0) }
        return FlowEvent(
            id: entryID,
            timestamp: timestamp,
            from: fromStep,
            to: toStep,
            transitionType: TransitionType(rawValue: transitionType) ?? .push,
            context: context,
            tags: tags,
            referenceURL: refURL,
            referenceID: referenceID,
            sourceFile: sourceFile,
            sourceFunction: sourceFunction,
            sourceLine: sourceLine
        )
    }

    static func from(_ flowEvent: FlowEvent) -> PersistedFlowEvent {
        let encoder = JSONEncoder()
        let fromInfoJSON = flowEvent.from?.additionalInfo.flatMap { try? encoder.encode($0) }
        let toInfoJSON = flowEvent.to.additionalInfo.flatMap { try? encoder.encode($0) }
        let contextJSON = flowEvent.context.flatMap { try? encoder.encode($0) }
        let tagsJSON = flowEvent.tags.flatMap { try? encoder.encode($0) }
        return PersistedFlowEvent(
            entryID: flowEvent.id,
            timestamp: flowEvent.timestamp,
            fromScreenName: flowEvent.from?.screenName,
            fromTransitionType: flowEvent.from?.transitionType.rawValue,
            fromTimestamp: flowEvent.from?.timestamp,
            fromInfoJSON: fromInfoJSON,
            toScreenName: flowEvent.to.screenName,
            toTransitionType: flowEvent.to.transitionType.rawValue,
            toTimestamp: flowEvent.to.timestamp,
            toInfoJSON: toInfoJSON,
            transitionType: flowEvent.transitionType.rawValue,
            contextJSON: contextJSON,
            tagsJSON: tagsJSON,
            referenceURLString: flowEvent.referenceURL?.absoluteString,
            referenceID: flowEvent.referenceID,
            sourceFile: flowEvent.sourceFile,
            sourceFunction: flowEvent.sourceFunction,
            sourceLine: flowEvent.sourceLine
        )
    }
}
