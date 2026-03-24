import Foundation

/// A lightweight wrapper around parsed JSON for recursive SwiftUI display.
enum JSONValue {
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([(key: String, value: JSONValue)])

    init(_ any: Any) {
        switch any {
        case let bool as Bool where CFGetTypeID(bool as CFTypeRef) == CFBooleanGetTypeID():
            self = .bool(bool)
        case let num as NSNumber:
            self = .number(num)
        case let str as String:
            self = .string(str)
        case let arr as [Any]:
            self = .array(arr.map { JSONValue($0) })
        case let dict as [String: Any]:
            self = .object(dict.keys.sorted().map { ($0, JSONValue(dict[$0]!)) })
        default:
            self = .null
        }
    }

    var summary: String {
        switch self {
        case .string(let s): "\"\(s)\""
        case .number(let n): n.stringValue
        case .bool(let b): b ? "true" : "false"
        case .null: "null"
		  case .array(let a): "[\(a.count) \(a.count == 1 ? "item" : "items")]"
        case .object(let o):
            if let preview = o.objectPreview {
                "{\(o.count) \(o.count == 1 ? "key" : "keys")} — \(preview)"
            } else {
                "{\(o.count) \(o.count == 1 ? "key" : "keys")}"
            }
        }
    }

    var isContainer: Bool {
        switch self {
        case .array, .object: true
        default: false
        }
    }

    /// Whether this container has at least one child that is also a container.
    var hasContainerChildren: Bool {
        switch self {
        case .array(let items): items.contains { $0.isContainer }
        case .object(let pairs): pairs.contains { $0.value.isContainer }
        default: false
        }
    }
}

private let previewKeys = ["name", "title", "label", "displayName", "display_name", "username", "email", "id", "key", "slug", "description"]

extension Array where Element == (key: String, value: JSONValue) {
    var objectPreview: String? {
        for candidate in previewKeys {
            if let match = first(where: { $0.key.caseInsensitiveCompare(candidate) == .orderedSame }) {
                switch match.value {
                case .string(let s): return s
                case .number(let n): return n.stringValue
                default: continue
                }
            }
        }
        // Fall back to the first simple string value
        if let first = first(where: { if case .string = $0.value { return true } else { return false } }) {
            if case .string(let s) = first.value { return s }
        }
        return nil
    }
}
