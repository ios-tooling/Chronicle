import Foundation
import SwiftData
import TagAlong

// MARK: - Persisted Event

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
            entryID: event.id,
            timestamp: event.timestamp,
            name: event.name,
            contextJSON: contextJSON,
            tagsJSON: tagsJSON,
            referenceURLString: event.referenceURL?.absoluteString,
            referenceID: event.referenceID,
            sourceFile: event.sourceFile,
            sourceFunction: event.sourceFunction,
            sourceLine: event.sourceLine
        )
    }
}

// MARK: - Persisted Network Log

@available(iOS 17, macOS 14, *)
@Model
final class PersistedNetworkLog {
    @Attribute(.unique) var entryID: UUID
    var timestamp: Date
    var url: String
    var method: String
    var requestHeadersJSON: Data?
    var requestBody: Data?
    var requestBodySize: Int?
    var statusCode: Int?
    var responseHeadersJSON: Data?
    var responseBody: Data?
    var responseBodySize: Int?
    var errorMessage: String?
    var wasCancelled: Bool?
    var startTime: Date
    var endTime: Date?
    var bytesSent: Int64
    var bytesReceived: Int64
    var linkedErrorID: UUID?
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
        url: String,
        method: String,
        requestHeadersJSON: Data?,
        requestBody: Data?,
        requestBodySize: Int?,
        statusCode: Int?,
        responseHeadersJSON: Data?,
        responseBody: Data?,
        responseBodySize: Int?,
        errorMessage: String?,
        wasCancelled: Bool = false,
        startTime: Date,
        endTime: Date?,
        bytesSent: Int64,
        bytesReceived: Int64,
        linkedErrorID: UUID?,
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
        self.url = url
        self.method = method
        self.requestHeadersJSON = requestHeadersJSON
        self.requestBody = requestBody
        self.requestBodySize = requestBodySize
        self.statusCode = statusCode
        self.responseHeadersJSON = responseHeadersJSON
        self.responseBody = responseBody
        self.responseBodySize = responseBodySize
        self.errorMessage = errorMessage
        self.wasCancelled = wasCancelled
        self.startTime = startTime
        self.endTime = endTime
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.linkedErrorID = linkedErrorID
        self.contextJSON = contextJSON
        self.tagsJSON = tagsJSON
        self.referenceURLString = referenceURLString
        self.referenceID = referenceID
        self.sourceFile = sourceFile
        self.sourceFunction = sourceFunction
        self.sourceLine = sourceLine
    }

    func toNetworkLog() -> NetworkLog {
        let decoder = JSONDecoder()
        let reqHeaders = requestHeadersJSON.flatMap {
            try? decoder.decode([String: String].self, from: $0)
        }
        let resHeaders = responseHeadersJSON.flatMap {
            try? decoder.decode([String: String].self, from: $0)
        }
        let context = contextJSON.flatMap { try? decoder.decode(EventMetadata.self, from: $0) }
        let tags = tagsJSON.flatMap { try? decoder.decode([Tag].self, from: $0) } ?? []
        let refURL = referenceURLString.flatMap { URL(string: $0) }
        return NetworkLog(
            id: entryID,
            timestamp: timestamp,
            url: URL(string: url) ?? URL(string: "https://unknown")!,
            method: method,
            requestHeaders: reqHeaders,
            requestBody: requestBody,
            requestBodySize: requestBodySize,
            statusCode: statusCode,
            responseHeaders: resHeaders,
            responseBody: responseBody,
            responseBodySize: responseBodySize,
            error: errorMessage,
            wasCancelled: wasCancelled ?? false,
            metrics: NetworkMetrics(
                startTime: startTime,
                endTime: endTime,
                bytesSent: bytesSent,
                bytesReceived: bytesReceived
            ),
            linkedErrorID: linkedErrorID,
            context: context,
            tags: tags,
            referenceURL: refURL,
            referenceID: referenceID,
            sourceFile: sourceFile,
            sourceFunction: sourceFunction,
            sourceLine: sourceLine
        )
    }

    static func from(_ log: NetworkLog) -> PersistedNetworkLog {
        let encoder = JSONEncoder()
        let reqJSON = log.requestHeaders.flatMap { try? encoder.encode($0) }
        let resJSON = log.responseHeaders.flatMap { try? encoder.encode($0) }
        let contextJSON = log.context.flatMap { try? encoder.encode($0) }
        let tagsJSON = log.tags.flatMap { try? encoder.encode($0) }
        return PersistedNetworkLog(
            entryID: log.id,
            timestamp: log.timestamp,
            url: log.url.absoluteString,
            method: log.method,
            requestHeadersJSON: reqJSON,
            requestBody: log.requestBody,
            requestBodySize: log.requestBodySize,
            statusCode: log.statusCode,
            responseHeadersJSON: resJSON,
            responseBody: log.responseBody,
            responseBodySize: log.responseBodySize,
            errorMessage: log.error,
            wasCancelled: log.wasCancelled,
            startTime: log.metrics.startTime,
            endTime: log.metrics.endTime,
            bytesSent: log.metrics.bytesSent,
            bytesReceived: log.metrics.bytesReceived,
            linkedErrorID: log.linkedErrorID,
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

// MARK: - Persisted Error Log

@available(iOS 17, macOS 14, *)
@Model
final class PersistedErrorLog {
    @Attribute(.unique) var entryID: UUID
    var timestamp: Date
    var domain: String
    var code: Int?
    var message: String
    var failureReason: String?
    var recoverySuggestion: String?
    var errorType: String
    var userInfoJSON: Data?
    var fullDescription: String
    var severity: String
    var contextJSON: Data?
    var callStackJSON: Data?
    var linkedNetworkLogID: UUID?
    var tagsJSON: Data?
    var referenceURLString: String?
    var referenceID: String?
    var sourceFile: String?
    var sourceFunction: String?
    var sourceLine: Int?

    init(
        entryID: UUID,
        timestamp: Date,
        domain: String,
        code: Int?,
        message: String,
        failureReason: String?,
        recoverySuggestion: String?,
        errorType: String,
        userInfoJSON: Data?,
        fullDescription: String,
        severity: String,
        contextJSON: Data?,
        callStackJSON: Data?,
        linkedNetworkLogID: UUID?,
        tagsJSON: Data?,
        referenceURLString: String?,
        referenceID: String?,
        sourceFile: String?,
        sourceFunction: String?,
        sourceLine: Int?
    ) {
        self.entryID = entryID
        self.timestamp = timestamp
        self.domain = domain
        self.code = code
        self.message = message
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.errorType = errorType
        self.userInfoJSON = userInfoJSON
        self.fullDescription = fullDescription
        self.severity = severity
        self.contextJSON = contextJSON
        self.callStackJSON = callStackJSON
        self.linkedNetworkLogID = linkedNetworkLogID
        self.tagsJSON = tagsJSON
        self.referenceURLString = referenceURLString
        self.referenceID = referenceID
        self.sourceFile = sourceFile
        self.sourceFunction = sourceFunction
        self.sourceLine = sourceLine
    }

    func toErrorLog() -> ErrorLog {
        let decoder = JSONDecoder()
        let userInfo = userInfoJSON.flatMap { try? decoder.decode([String: String].self, from: $0) }
        let context = contextJSON.flatMap { try? decoder.decode(EventMetadata.self, from: $0) }
        let callStack = callStackJSON.flatMap { try? decoder.decode([String].self, from: $0) }
        let tags = tagsJSON.flatMap { try? decoder.decode([Tag].self, from: $0) } ?? []
        let refURL = referenceURLString.flatMap { URL(string: $0) }

        return ErrorLog(
            id: entryID,
            timestamp: timestamp,
            domain: domain,
            code: code,
            message: message,
            failureReason: failureReason,
            recoverySuggestion: recoverySuggestion,
            errorType: errorType,
            userInfo: userInfo,
            fullDescription: fullDescription,
            severity: ErrorSeverity(rawValue: severity) ?? .error,
            context: context,
            callStackSymbols: callStack,
            linkedNetworkLogID: linkedNetworkLogID,
            tags: tags,
            referenceURL: refURL,
            referenceID: referenceID,
            sourceFile: sourceFile,
            sourceFunction: sourceFunction,
            sourceLine: sourceLine
        )
    }

    static func from(_ errorLog: ErrorLog) -> PersistedErrorLog {
        let encoder = JSONEncoder()
        let userInfoJSON = errorLog.userInfo.flatMap { try? encoder.encode($0) }
        let contextJSON = errorLog.context.flatMap { try? encoder.encode($0) }
        let callStackJSON = errorLog.callStackSymbols.flatMap { try? encoder.encode($0) }
        let tagsJSON = errorLog.tags.flatMap { try? encoder.encode($0) }

        return PersistedErrorLog(
            entryID: errorLog.id,
            timestamp: errorLog.timestamp,
            domain: errorLog.domain,
            code: errorLog.code,
            message: errorLog.message,
            failureReason: errorLog.failureReason,
            recoverySuggestion: errorLog.recoverySuggestion,
            errorType: errorLog.errorType,
            userInfoJSON: userInfoJSON,
            fullDescription: errorLog.fullDescription,
            severity: errorLog.severity.rawValue,
            contextJSON: contextJSON,
            callStackJSON: callStackJSON,
            linkedNetworkLogID: errorLog.linkedNetworkLogID,
            tagsJSON: tagsJSON,
            referenceURLString: errorLog.referenceURL?.absoluteString,
            referenceID: errorLog.referenceID,
            sourceFile: errorLog.sourceFile,
            sourceFunction: errorLog.sourceFunction,
            sourceLine: errorLog.sourceLine
        )
    }
}

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
