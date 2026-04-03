import Foundation
import TagAlong

/// Logs arbitrary errors, extracting as much information as possible.
@available(iOS 17, macOS 14, *)
public final class ErrorTracker: Sendable {
    private let storage: SwiftDataStorage

    init(storage: SwiftDataStorage) {
        self.storage = storage
    }

    /// Logs any Swift `Error`, extracting all available information.
    ///
    /// Captures: error type, domain, code, localized descriptions, user info,
    /// and optionally the call stack and custom context.
    public func log(
        _ error: Error,
        severity: ErrorSeverity = .error,
        context: EventMetadata? = nil,
        captureCallStack: Bool = false,
        tags: TagCollection? = nil,
        referenceURL: URL? = nil,
        referenceID: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let errorLog = makeErrorLog(
            from: error,
            severity: severity,
            context: context,
            captureCallStack: captureCallStack,
            tags: tags,
            referenceURL: referenceURL,
            referenceID: referenceID,
            file: file,
            function: function,
            line: line
        )
        storage.store(errorLog)
    }

    /// Logs an ErrorLog entry directly.
    public func log(_ errorLog: ErrorLog) {
        storage.store(errorLog)
    }

    /// Returns recent error logs, up to the specified limit.
    public func recentErrors(limit: Int = 100) -> [ErrorLog] {
        let query = StorageQuery(categories: [.error], limit: limit)
        return storage.entries(matching: query).compactMap { $0 as? ErrorLog }
    }

    /// Returns all stored error logs.
    public func allErrors() -> [ErrorLog] {
        let query = StorageQuery(categories: [.error])
        return storage.entries(matching: query).compactMap { $0 as? ErrorLog }
    }

    /// Returns error logs filtered by severity.
    public func errors(withSeverity severity: ErrorSeverity) -> [ErrorLog] {
        allErrors().filter { $0.severity == severity }
    }

    // MARK: - Error Extraction

    func makeErrorLog(
        from error: Error,
        id: UUID = UUID(),
        severity: ErrorSeverity = .error,
        context: EventMetadata? = nil,
        captureCallStack: Bool = false,
        tags: TagCollection? = nil,
        referenceURL: URL? = nil,
        referenceID: String? = nil,
        linkedNetworkLogID: UUID? = nil,
        file: String,
        function: String,
        line: Int
    ) -> ErrorLog {
        let nsError = error as NSError
        let errorType = String(describing: type(of: error))

        // Extract user info, converting values to strings
        var userInfoStrings: [String: String]?
        if !nsError.userInfo.isEmpty {
            var dict: [String: String] = [:]
            for (key, value) in nsError.userInfo {
                // Skip keys that are already captured in dedicated fields
                if key == NSLocalizedDescriptionKey ||
                   key == NSLocalizedFailureReasonErrorKey ||
                   key == NSLocalizedRecoverySuggestionErrorKey {
                    continue
                }
                dict[key] = String(describing: value)
            }
            if !dict.isEmpty {
                userInfoStrings = dict
            }
        }

        // Build full description including underlying errors
        let fullDescription = buildFullDescription(error)

        // Capture call stack if requested
        let stack = captureCallStack ? Thread.callStackSymbols : nil

        return ErrorLog(
            id: id,
            domain: nsError.domain,
            code: nsError.code,
            message: nsError.localizedDescription,
            failureReason: nsError.localizedFailureReason,
            recoverySuggestion: nsError.localizedRecoverySuggestion,
            errorType: errorType,
            userInfo: userInfoStrings,
            fullDescription: fullDescription,
            severity: severity,
            context: context,
            callStackSymbols: stack,
            linkedNetworkLogID: linkedNetworkLogID,
            tags: tags,
            referenceURL: referenceURL,
            referenceID: referenceID,
            sourceFile: (file as NSString).lastPathComponent,
            sourceFunction: function,
            sourceLine: line
        )
    }

    private func buildFullDescription(_ error: Error) -> String {
        var parts: [String] = []
        let nsError = error as NSError

        parts.append("\(type(of: error)): \(error.localizedDescription)")

        if let reason = nsError.localizedFailureReason {
            parts.append("Reason: \(reason)")
        }

        if let suggestion = nsError.localizedRecoverySuggestion {
            parts.append("Suggestion: \(suggestion)")
        }

        // Walk the underlying error chain
        var underlying: NSError? = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        var depth = 1
        while let current = underlying, depth <= 5 {
            parts.append("Underlying (\(depth)): \(current.domain) [\(current.code)] \(current.localizedDescription)")
            underlying = current.userInfo[NSUnderlyingErrorKey] as? NSError
            depth += 1
        }

        return parts.joined(separator: "\n")
    }
}
