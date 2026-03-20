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

        let events = sorted.compactMap { $0 as? Event }
        let networkLogs = sorted.compactMap { $0 as? NetworkLog }
        let flowEvents = sorted.compactMap { $0 as? FlowEvent }
        let errorLogs = sorted.compactMap { $0 as? ErrorLog }

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
        md += "## Summary\n\n"
        md += "| Category | Count |\n"
        md += "|----------|-------|\n"
        md += "| Events | \(events.count) |\n"
        md += "| Network | \(networkLogs.count) |\n"
        md += "| Flow | \(flowEvents.count) |\n"
        md += "| Errors | \(errorLogs.count) |\n"

        if !networkLogs.isEmpty {
            let errorCount = networkLogs.filter { $0.error != nil || ($0.statusCode ?? 0) >= 400 }.count
            let errorRate = Double(errorCount) / Double(networkLogs.count) * 100
            md += "\n**Network Error Rate:** \(String(format: "%.1f", errorRate))% (\(errorCount)/\(networkLogs.count))\n"

            let durations = networkLogs.compactMap { $0.metrics.duration }
            if !durations.isEmpty {
                let avg = durations.reduce(0, +) / Double(durations.count)
                md += "**Avg Response Time:** \(String(format: "%.3f", avg))s\n"
            }
        }
        md += "\n"

        // Events Section
        if !events.isEmpty {
            md += "## Events\n\n"
            md += "| Timestamp | Name | Metadata |\n"
            md += "|-----------|------|----------|\n"
            for event in events {
                let ts = isoFormatter.string(from: event.timestamp)
                let meta = event.metadata?.description ?? "—"
                md += "| \(ts) | \(event.name) | \(meta) |\n"
            }
            md += "\n"
        }

        // Network Section
        if !networkLogs.isEmpty {
            md += "## Network\n\n"
            md += "| Timestamp | Method | URL | Status | Duration | Error |\n"
            md += "|-----------|--------|-----|--------|----------|-------|\n"
            for log in networkLogs {
                let ts = isoFormatter.string(from: log.timestamp)
                let status = log.statusCode.map(String.init) ?? "—"
                let duration = log.metrics.duration.map { String(format: "%.3fs", $0) } ?? "—"
                let error = log.error ?? "—"
                let urlString = log.url.absoluteString
                md += "| \(ts) | \(log.method) | \(urlString) | \(status) | \(duration) | \(error) |\n"
            }
            md += "\n"
        }

        // Flow Section
        if !flowEvents.isEmpty {
            md += "## Flow\n\n"
            md += "| Timestamp | From | To | Transition |\n"
            md += "|-----------|------|----|------------|\n"
            for flow in flowEvents {
                let ts = isoFormatter.string(from: flow.timestamp)
                let from = flow.from?.screenName ?? "—"
                md += "| \(ts) | \(from) | \(flow.to.screenName) | \(flow.transitionType.rawValue) |\n"
            }
            md += "\n"
        }

        // Errors Section
        if !errorLogs.isEmpty {
            md += "## Errors\n\n"
            md += "| Timestamp | Severity | Type | Domain | Code | Message | Failure Reason |\n"
            md += "|-----------|----------|------|--------|------|---------|----------------|\n"
            for error in errorLogs {
                let ts = isoFormatter.string(from: error.timestamp)
                let code = error.code.map(String.init) ?? "—"
                let reason = error.failureReason ?? "—"
                md += "| \(ts) | \(error.severity.rawValue.uppercased()) | \(error.errorType) | \(error.domain) | \(code) | \(error.message) | \(reason) |\n"
            }
            md += "\n"

            // Error severity breakdown
            let severityCounts = Dictionary(grouping: errorLogs, by: { $0.severity })
            md += "### Error Severity Breakdown\n\n"
            md += "| Severity | Count |\n"
            md += "|----------|-------|\n"
            for severity in [ErrorSeverity.critical, .error, .warning, .info, .debug] {
                let count = severityCounts[severity]?.count ?? 0
                if count > 0 {
                    md += "| \(severity.rawValue.uppercased()) | \(count) |\n"
                }
            }
            md += "\n"
        }

        return md
    }
}
