import Foundation
import SwiftData
import TagAlong

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
