import Foundation
import SwiftData
import TagAlong

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
