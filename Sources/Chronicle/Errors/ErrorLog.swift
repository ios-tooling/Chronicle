import Foundation

/// Severity level for logged errors.
public enum ErrorSeverity: String, Codable, Sendable {
    case debug
    case info
    case warning
    case error
    case critical
}

/// Represents a logged error with as much detail as possible extracted from the source error.
public struct ErrorLog: ChronicleEntry {
    public let id: UUID
    public let timestamp: Date
    public let category: EntryCategory = .error

    /// The error domain (e.g., NSError domain, or the type name of the error).
    public let domain: String

    /// The error code, if available (from NSError or similar).
    public let code: Int?

    /// The localized description of the error.
    public let message: String

    /// The underlying error's localized failure reason, if available.
    public let failureReason: String?

    /// The underlying error's recovery suggestion, if available.
    public let recoverySuggestion: String?

    /// The full type name of the original error (e.g., "DecodingError", "URLError").
    public let errorType: String

    /// The user info dictionary keys and string-representable values from NSError.
    public let userInfo: [String: String]?

    /// A textual representation of the full error (including nested/underlying errors).
    public let fullDescription: String

    /// The severity level assigned to this error.
    public let severity: ErrorSeverity

    /// Optional context about where the error occurred (e.g., function name, file, screen).
    public let context: EventMetadata?

    /// The call stack symbols at the time of logging, if captured.
    public let callStackSymbols: [String]?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        domain: String,
        code: Int? = nil,
        message: String,
        failureReason: String? = nil,
        recoverySuggestion: String? = nil,
        errorType: String,
        userInfo: [String: String]? = nil,
        fullDescription: String,
        severity: ErrorSeverity = .error,
        context: EventMetadata? = nil,
        callStackSymbols: [String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.domain = domain
        self.code = code
        self.message = message
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.errorType = errorType
        self.userInfo = userInfo
        self.fullDescription = fullDescription
        self.severity = severity
        self.context = context
        self.callStackSymbols = callStackSymbols
    }

    // Custom Codable to handle the constant category
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, category, domain, code, message, failureReason
        case recoverySuggestion, errorType, userInfo, fullDescription
        case severity, context, callStackSymbols
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(domain, forKey: .domain)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(failureReason, forKey: .failureReason)
        try container.encodeIfPresent(recoverySuggestion, forKey: .recoverySuggestion)
        try container.encode(errorType, forKey: .errorType)
        try container.encodeIfPresent(userInfo, forKey: .userInfo)
        try container.encode(fullDescription, forKey: .fullDescription)
        try container.encode(severity, forKey: .severity)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encodeIfPresent(callStackSymbols, forKey: .callStackSymbols)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        domain = try container.decode(String.self, forKey: .domain)
        code = try container.decodeIfPresent(Int.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        failureReason = try container.decodeIfPresent(String.self, forKey: .failureReason)
        recoverySuggestion = try container.decodeIfPresent(String.self, forKey: .recoverySuggestion)
        errorType = try container.decode(String.self, forKey: .errorType)
        userInfo = try container.decodeIfPresent([String: String].self, forKey: .userInfo)
        fullDescription = try container.decode(String.self, forKey: .fullDescription)
        severity = try container.decode(ErrorSeverity.self, forKey: .severity)
        context = try container.decodeIfPresent(EventMetadata.self, forKey: .context)
        callStackSymbols = try container.decodeIfPresent([String].self, forKey: .callStackSymbols)
    }
}
