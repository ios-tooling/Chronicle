import Foundation

/// Exports Chronicle entries as a structured markdown report.
public struct MarkdownExporter: ExportDestination {
    /// Optional title for the report.
    public var title: String

    public init(title: String = "Chronicle Report") {
        self.title = title
    }

    @discardableResult
    public func export(_ entries: [any ChronicleEntry]) throws -> Data? {
        let markdown = generateMarkdown(from: entries)
        return markdown.data(using: .utf8)
    }

    /// Generates a markdown report string from the given entries.
    public func generateMarkdown(from entries: [any ChronicleEntry]) -> String {
        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        var errorLogsByID: [UUID: ErrorLog] = [:]
        for case let errorLog as ErrorLog in sorted {
            errorLogsByID[errorLog.id] = errorLog
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        let isoFormatter = ISO8601DateFormatter()

        var md = ""

        // Header
        md += "# \(title)\n\n"
        if let earliest = sorted.first?.timestamp, let latest = sorted.last?.timestamp {
            md += "**Time Range:** \(formatter.string(from: earliest)) — \(formatter.string(from: latest))  \n"
        }
        md += "**Generated:** \(formatter.string(from: Date()))  \n"
        md += "**Total Entries:** \(entries.count)\n\n"

        // Summary
        let counts = Dictionary(grouping: sorted, by: \.category)
        md += "## Summary\n\n"
        md += "| Category | Count |\n"
        md += "|----------|-------|\n"
        for (category, group) in counts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            md += "| \(category.displayName) | \(group.count) |\n"
        }
        md += "\n"

        // Chronological entries
        md += "## Timeline\n\n"
        for entry in sorted {
            let ts = isoFormatter.string(from: entry.timestamp)
            md += "**\(entry.category.displayName)** \(ts)\n\n"
            md += "- " + formatEntry(entry, errorLogsByID: errorLogsByID)
            md += "\n---\n"
        }

        return md
    }

    private func formatEntry(_ entry: any ChronicleEntry, errorLogsByID: [UUID: ErrorLog]) -> String {
        switch entry {
        case let event as Event:
            var md = "**\(event.name)**"
            if let ctx = event.context { md += "  \nContext: \(ctx)" }
            return md + "\n"

        case let log as NetworkLog:
            var md = "**\(log.method)** `\(log.url.absoluteString)`"
            if let status = log.statusCode { md += " → \(status)" }
            if let size = log.responseBodySize { md += " (\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))" }
            if let duration = log.metrics.duration { md += String(format: " (%.0fms)", duration * 1000) }
            md += "\n"
            if let linkedErrorID = log.linkedErrorID, let error = errorLogsByID[linkedErrorID] {
                md += "  Error: \(errorIdentity(error))\n"
            } else if let error = log.error {
                md += "  Error: \(inline(error))\n"
            }
            return md

        case let flow as FlowEvent:
            let from = flow.from?.screenName ?? "—"
            return "\(from) → **\(flow.to.screenName)** (\(flow.transitionType.rawValue))\n"

        case let error as ErrorLog:
            return formatError(error)

        case let ck as CloudKitLog:
            let dir: String = switch ck.operation {
            case .upload: "Upload"
            case .download: "Download"
            case .deleted: "Delete"
            case .zoneCreated: "Zone Modified"
            case .zoneDeleted: "Zone Deleted"
            }
            var md: String = switch ck.operation {
            case .zoneCreated, .zoneDeleted: "**\(dir)** `\(ck.zoneName)`"
            default: "**\(dir)** \(ck.recordType) `\(ck.recordName)` in \(ck.zoneName)"
            }
            if let size = ck.recordSize { md += " (\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))" }
            if let duration = ck.duration { md += String(format: " %.0fms", duration * 1000) }
            md += "\n"
            if let error = ck.error { md += "Error: \(error)\n" }
            return md

        default:
            return "\(entry.displaySummary)\n"
        }
    }

    private func formatError(_ error: ErrorLog) -> String {
        var md = "**\(error.severity.rawValue.uppercased())** **\(inline(error.errorType))**: \(inline(error.message))\n"
        md += "  Domain: `\(inline(error.domain))`  \n"
        if let code = error.code {
            md += "  Code: `\(code)`"
            if error.domain == NSURLErrorDomain {
                md += " (`\(URLError.Code(rawValue: code).chronicleName)`)"
            }
            md += "  \n"
        }
        if let reason = error.failureReason {
            md += "  Failure Reason: \(inline(reason))  \n"
        }
        if let suggestion = error.recoverySuggestion {
            md += "  Recovery Suggestion: \(inline(suggestion))  \n"
        }

        let defaultFullDescription = "\(error.errorType): \(error.message)"
        if error.fullDescription != error.message, error.fullDescription != defaultFullDescription {
            md += "  Details:\n"
            md += quoted(error.fullDescription)
        }

        if let userInfo = error.userInfo, !userInfo.isEmpty {
            md += "  User Info:\n"
            for key in userInfo.keys.sorted() {
                md += "    - `\(inline(key))`: \(inline(userInfo[key] ?? ""))\n"
            }
        }
        if let context = error.context, !context.isEmpty {
            md += "  Context:\n"
            for key in context.keys.sorted() {
                md += "    - `\(inline(key))`: \(inline(String(describing: context[key]!)))\n"
            }
        }
        if let linkedNetworkLogID = error.linkedNetworkLogID {
            md += "  Linked Network Log: `\(linkedNetworkLogID.uuidString)`  \n"
        }

        var source: [String] = []
        if let file = error.sourceFile {
            source.append(file + (error.sourceLine.map { ":\($0)" } ?? ""))
        }
        if let function = error.sourceFunction {
            source.append(function)
        }
        if !source.isEmpty {
            md += "  Source: `\(inline(source.joined(separator: " — ")))`  \n"
        }

        if let callStack = error.callStackSymbols, !callStack.isEmpty {
            md += "  Call Stack:\n"
            for frame in callStack {
                md += "    - `\(inline(frame))`\n"
            }
        }
        return md
    }

    private func errorIdentity(_ error: ErrorLog) -> String {
        var identity = "`\(inline(error.domain))`"
        if let code = error.code {
            identity += " code `\(code)`"
            if error.domain == NSURLErrorDomain {
                identity += " (`\(URLError.Code(rawValue: code).chronicleName)`)"
            }
        }
        return "\(identity) — \(inline(error.message))"
    }

    private func quoted(_ value: String) -> String {
        value.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "  > \($0)\n" }
            .joined()
    }

    private func inline(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}
