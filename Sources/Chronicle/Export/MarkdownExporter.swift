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
            md += "- " + formatEntry(entry)
            md += "\n---\n"
        }

        return md
    }

    private func formatEntry(_ entry: any ChronicleEntry) -> String {
        switch entry {
        case let event as Event:
            var md = "**\(event.name)**"
            if let ctx = event.context { md += "  \nContext: \(ctx)" }
            return md + "\n"

        case let log as NetworkLog:
            var md = "**\(log.method)** `\(log.url.absoluteString)`"
            if let status = log.statusCode { md += " → \(status)" }
            if let duration = log.metrics.duration { md += String(format: " (%.0fms)", duration * 1000) }
            md += "\n"
            if let error = log.error { md += "Error: \(error)\n" }
            return md

        case let flow as FlowEvent:
            let from = flow.from?.screenName ?? "—"
            return "\(from) → **\(flow.to.screenName)** (\(flow.transitionType.rawValue))\n"

        case let error as ErrorLog:
            var md = "**\(error.severity.rawValue.uppercased())** \(error.errorType): \(error.message)\n"
            if let reason = error.failureReason { md += "Reason: \(reason)\n" }
            return md

        case let ck as CloudKitLog:
            let dir: String = switch ck.operation {
            case .upload: "Upload"
            case .download: "Download"
            case .deleted: "Delete"
            case .zoneCreated: "Zone Created"
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
}
