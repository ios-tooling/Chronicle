import Foundation
import SwiftData

// MARK: - Persisted Event

@Model
final class PersistedEvent {
    @Attribute(.unique) var entryID: UUID
    var timestamp: Date
    var name: String
    var metadataJSON: Data?

    init(entryID: UUID, timestamp: Date, name: String, metadataJSON: Data?) {
        self.entryID = entryID
        self.timestamp = timestamp
        self.name = name
        self.metadataJSON = metadataJSON
    }

    func toEvent() -> Event {
        var metadata: EventMetadata?
        if let data = metadataJSON {
            metadata = try? JSONDecoder().decode(EventMetadata.self, from: data)
        }
        return Event(id: entryID, timestamp: timestamp, name: name, metadata: metadata)
    }

    static func from(_ event: Event) -> PersistedEvent {
        let metadataJSON = event.metadata.flatMap { try? JSONEncoder().encode($0) }
        return PersistedEvent(
            entryID: event.id,
            timestamp: event.timestamp,
            name: event.name,
            metadataJSON: metadataJSON
        )
    }
}

// MARK: - Persisted Network Log

@Model
final class PersistedNetworkLog {
    @Attribute(.unique) var entryID: UUID
    var timestamp: Date
    var url: String
    var method: String
    var requestHeadersJSON: Data?
    var requestBodySize: Int?
    var statusCode: Int?
    var responseHeadersJSON: Data?
    var responseBodySize: Int?
    var errorMessage: String?
    var startTime: Date
    var endTime: Date?
    var bytesSent: Int64
    var bytesReceived: Int64

    init(
        entryID: UUID,
        timestamp: Date,
        url: String,
        method: String,
        requestHeadersJSON: Data?,
        requestBodySize: Int?,
        statusCode: Int?,
        responseHeadersJSON: Data?,
        responseBodySize: Int?,
        errorMessage: String?,
        startTime: Date,
        endTime: Date?,
        bytesSent: Int64,
        bytesReceived: Int64
    ) {
        self.entryID = entryID
        self.timestamp = timestamp
        self.url = url
        self.method = method
        self.requestHeadersJSON = requestHeadersJSON
        self.requestBodySize = requestBodySize
        self.statusCode = statusCode
        self.responseHeadersJSON = responseHeadersJSON
        self.responseBodySize = responseBodySize
        self.errorMessage = errorMessage
        self.startTime = startTime
        self.endTime = endTime
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
    }

    func toNetworkLog() -> NetworkLog {
        let decoder = JSONDecoder()
        let reqHeaders = requestHeadersJSON.flatMap {
            try? decoder.decode([String: String].self, from: $0)
        }
        let resHeaders = responseHeadersJSON.flatMap {
            try? decoder.decode([String: String].self, from: $0)
        }
        return NetworkLog(
            id: entryID,
            timestamp: timestamp,
            url: URL(string: url) ?? URL(string: "https://unknown")!,
            method: method,
            requestHeaders: reqHeaders,
            requestBodySize: requestBodySize,
            statusCode: statusCode,
            responseHeaders: resHeaders,
            responseBodySize: responseBodySize,
            error: errorMessage,
            metrics: NetworkMetrics(
                startTime: startTime,
                endTime: endTime,
                bytesSent: bytesSent,
                bytesReceived: bytesReceived
            )
        )
    }

    static func from(_ log: NetworkLog) -> PersistedNetworkLog {
        let encoder = JSONEncoder()
        let reqJSON = log.requestHeaders.flatMap { try? encoder.encode($0) }
        let resJSON = log.responseHeaders.flatMap { try? encoder.encode($0) }
        return PersistedNetworkLog(
            entryID: log.id,
            timestamp: log.timestamp,
            url: log.url.absoluteString,
            method: log.method,
            requestHeadersJSON: reqJSON,
            requestBodySize: log.requestBodySize,
            statusCode: log.statusCode,
            responseHeadersJSON: resJSON,
            responseBodySize: log.responseBodySize,
            errorMessage: log.error,
            startTime: log.metrics.startTime,
            endTime: log.metrics.endTime,
            bytesSent: log.metrics.bytesSent,
            bytesReceived: log.metrics.bytesReceived
        )
    }
}

// MARK: - Persisted Flow Event

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
        transitionType: String
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
        return FlowEvent(
            id: entryID,
            timestamp: timestamp,
            from: fromStep,
            to: toStep,
            transitionType: TransitionType(rawValue: transitionType) ?? .push
        )
    }

    static func from(_ flowEvent: FlowEvent) -> PersistedFlowEvent {
        let encoder = JSONEncoder()
        let fromInfoJSON = flowEvent.from?.additionalInfo.flatMap { try? encoder.encode($0) }
        let toInfoJSON = flowEvent.to.additionalInfo.flatMap { try? encoder.encode($0) }
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
            transitionType: flowEvent.transitionType.rawValue
        )
    }
}

// MARK: - Persisted Error Log

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
        callStackJSON: Data?
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
    }

    func toErrorLog() -> ErrorLog {
        let decoder = JSONDecoder()
        let userInfo = userInfoJSON.flatMap { try? decoder.decode([String: String].self, from: $0) }
        let context = contextJSON.flatMap { try? decoder.decode(EventMetadata.self, from: $0) }
        let callStack = callStackJSON.flatMap { try? decoder.decode([String].self, from: $0) }

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
            callStackSymbols: callStack
        )
    }

    static func from(_ errorLog: ErrorLog) -> PersistedErrorLog {
        let encoder = JSONEncoder()
        let userInfoJSON = errorLog.userInfo.flatMap { try? encoder.encode($0) }
        let contextJSON = errorLog.context.flatMap { try? encoder.encode($0) }
        let callStackJSON = errorLog.callStackSymbols.flatMap { try? encoder.encode($0) }

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
            callStackJSON: callStackJSON
        )
    }
}
