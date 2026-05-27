import Foundation

extension Error {
    /// Extracts richly-structured metadata from this error.
    ///
    /// Handles DecodingError, EncodingError, URLError, and CocoaError with
    /// type-specific fields. All errors get errorType, errorDomain, errorCode,
    /// and any LocalizedError protocol fields.
    public var eventMetadata: EventMetadata {
        var dict = baseErrorMetadata
        switch self {
        case let e as DecodingError:  dict.merge(e.extractedMetadata) { $1 }
        case let e as EncodingError:  dict.merge(e.extractedMetadata) { $1 }
        case let e as URLError:       dict.merge(e.extractedMetadata) { $1 }
        case let e as CocoaError:     dict.merge(e.extractedMetadata) { $1 }
        default: break
        }
        return EventMetadata(dict)
    }

    private var baseErrorMetadata: [String: AnyCodableValue] {
        let ns = self as NSError
        var dict: [String: AnyCodableValue] = [
            "errorType":   .string(String(describing: type(of: self))),
            "errorDomain": .string(ns.domain),
            "errorCode":   .int(ns.code)
        ]
        if let e = self as? any LocalizedError {
            if let v = e.errorDescription    { dict["errorDescription"] = .string(v) }
            if let v = e.failureReason       { dict["failureReason"] = .string(v) }
            if let v = e.recoverySuggestion  { dict["recoverySuggestion"] = .string(v) }
        }
        return dict
    }
}

private extension DecodingError {
    var extractedMetadata: [String: AnyCodableValue] {
        switch self {
        case .typeMismatch(let type, let ctx):
            return ["case": "typeMismatch", "expectedType": .string("\(type)"),
                    "codingPath": .string(ctx.codingPath.dotted), "detail": .string(ctx.debugDescription)]
        case .valueNotFound(let type, let ctx):
            return ["case": "valueNotFound", "expectedType": .string("\(type)"),
                    "codingPath": .string(ctx.codingPath.dotted), "detail": .string(ctx.debugDescription)]
        case .keyNotFound(let key, let ctx):
            return ["case": "keyNotFound", "missingKey": .string(key.stringValue),
                    "codingPath": .string(ctx.codingPath.dotted), "detail": .string(ctx.debugDescription)]
        case .dataCorrupted(let ctx):
            return ["case": "dataCorrupted",
                    "codingPath": .string(ctx.codingPath.dotted), "detail": .string(ctx.debugDescription)]
        @unknown default:
            return ["case": "unknown"]
        }
    }
}

private extension EncodingError {
    var extractedMetadata: [String: AnyCodableValue] {
        switch self {
        case .invalidValue(let value, let ctx):
            return ["case": "invalidValue", "value": .string("\(value)"),
                    "codingPath": .string(ctx.codingPath.dotted), "detail": .string(ctx.debugDescription)]
        @unknown default:
            return ["case": "unknown"]
        }
    }
}

private extension URLError {
    var extractedMetadata: [String: AnyCodableValue] {
        var dict: [String: AnyCodableValue] = [
            "errorCode":     .int(code.rawValue),
            "errorCodeName": .string(code.humanReadableName)
        ]
        if let url = failingURL { dict["failingURL"] = .string(url.absoluteString) }
        return dict
    }
}

private extension URLError.Code {
    var humanReadableName: String {
        switch self {
        case .cancelled:               return "cancelled"
        case .badURL:                  return "badURL"
        case .timedOut:                return "timedOut"
        case .unsupportedURL:          return "unsupportedURL"
        case .cannotFindHost:          return "cannotFindHost"
        case .cannotConnectToHost:     return "cannotConnectToHost"
        case .networkConnectionLost:   return "networkConnectionLost"
        case .dnsLookupFailed:         return "dnsLookupFailed"
        case .notConnectedToInternet:  return "notConnectedToInternet"
        case .badServerResponse:       return "badServerResponse"
        case .secureConnectionFailed:  return "secureConnectionFailed"
        case .userAuthenticationRequired: return "userAuthenticationRequired"
        case .cannotDecodeContentData: return "cannotDecodeContentData"
        case .cannotParseResponse:     return "cannotParseResponse"
        case .dataLengthExceedsMaximum: return "dataLengthExceedsMaximum"
        default:                       return "urlError(\(rawValue))"
        }
    }
}

private extension CocoaError {
    var extractedMetadata: [String: AnyCodableValue] {
        var dict: [String: AnyCodableValue] = ["cocoaErrorCode": .int(code.rawValue)]
        if let url  = userInfo[NSURLErrorKey] as? URL        { dict["fileURL"] = .string(url.path) }
        if let path = userInfo[NSFilePathErrorKey] as? String { dict["filePath"] = .string(path) }
        if let underlying = userInfo[NSUnderlyingErrorKey] as? NSError {
            dict["underlyingDomain"] = .string(underlying.domain)
            dict["underlyingCode"]   = .int(underlying.code)
        }
        return dict
    }
}

private extension [CodingKey] {
    var dotted: String {
        map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }.joined(separator: ".")
    }
}
