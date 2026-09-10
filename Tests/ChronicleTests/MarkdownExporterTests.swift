import Testing
import Foundation
@testable import Chronicle

@Suite("MarkdownExporter Tests")
struct MarkdownExporterTests {
    @Test("Generate report with all entry types")
    func generateFullReport() throws {
        let exporter = MarkdownExporter(title: "Test Report")

        let entries: [any ChronicleEntry] = [
            Event(name: "app_launched"),
            NetworkLog(
                url: URL(string: "https://api.example.com/data")!,
                method: "GET",
                statusCode: 200,
                metrics: NetworkMetrics(
                    startTime: Date(),
                    endTime: Date().addingTimeInterval(0.5),
                    bytesSent: 0,
                    bytesReceived: 1024
                )
            ),
            FlowEvent(
                from: nil,
                to: FlowStep(screenName: "HomeScreen"),
                transitionType: .push
            ),
            ErrorLog(
                domain: "com.test",
                code: 42,
                message: "Something broke",
                errorType: "TestError",
                fullDescription: "TestError: Something broke",
                severity: .critical
            )
        ]

        let markdown = exporter.generateMarkdown(from: entries)

        #expect(markdown.contains("# Test Report"))
        #expect(markdown.contains("## Summary"))
        #expect(markdown.contains("## Timeline"))
        #expect(markdown.contains("app_launched"))
        #expect(markdown.contains("api.example.com"))
        #expect(markdown.contains("HomeScreen"))
        #expect(markdown.contains("Something broke"))
        #expect(markdown.contains("CRITICAL"))
    }

    @Test("Report contains summary statistics")
    func summaryStatistics() throws {
        let exporter = MarkdownExporter()

        let entries: [any ChronicleEntry] = [
            Event(name: "event1"),
            Event(name: "event2"),
            NetworkLog(
                url: URL(string: "https://example.com")!,
                method: "GET",
                statusCode: 200,
                metrics: NetworkMetrics(startTime: Date(), endTime: Date().addingTimeInterval(0.1))
            ),
            NetworkLog(
                url: URL(string: "https://example.com/fail")!,
                method: "POST",
                statusCode: 500,
                metrics: NetworkMetrics(startTime: Date(), endTime: Date().addingTimeInterval(2.0))
            )
        ]

        let markdown = exporter.generateMarkdown(from: entries)

        #expect(markdown.contains("| Events | 2 |"))
        #expect(markdown.contains("| Network | 2 |"))
        #expect(markdown.contains("**Total Entries:** 4"))
    }

    @Test("Report with no entries")
    func emptyReport() throws {
        let exporter = MarkdownExporter(title: "Empty Report")
        let markdown = exporter.generateMarkdown(from: [])

        #expect(markdown.contains("# Empty Report"))
        #expect(markdown.contains("**Total Entries:** 0"))
        #expect(!markdown.contains("## Events"))
        #expect(!markdown.contains("## Network"))
        #expect(!markdown.contains("## Flow"))
    }

    @Test("Export returns UTF-8 data")
    func exportReturnsData() throws {
        let exporter = MarkdownExporter()

        let entries: [any ChronicleEntry] = [
            Event(name: "test")
        ]

        let data = try exporter.export(entries)
        #expect(data != nil)

        let string = String(data: data!, encoding: .utf8)
        #expect(string != nil)
        #expect(string!.contains("Chronicle Report"))
    }

    @Test("Report includes rich error diagnostics and resolves linked network errors")
    func richErrorDiagnostics() {
        let exporter = MarkdownExporter()
        let networkID = UUID()
        let errorID = UUID()
        let error = ErrorLog(
            id: errorID,
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            message: "NSURLError",
            failureReason: "The device is offline",
            recoverySuggestion: "Check the network connection",
            errorType: "NSError",
            userInfo: ["NSErrorFailingURLStringKey": "https://api.example.com/data"],
            fullDescription: "NSError: NSURLError\nUnderlying (1): NetworkExtension [7] Radio unavailable",
            severity: .error,
            context: ["operation": "fetchData"],
            callStackSymbols: ["0 ChronicleTests richErrorDiagnostics"],
            linkedNetworkLogID: networkID,
            sourceFile: "APIClient.swift",
            sourceFunction: "fetchData()",
            sourceLine: 42
        )
        let network = NetworkLog(
            id: networkID,
            url: URL(string: "https://api.example.com/data")!,
            method: "GET",
            error: "NSURLError",
            linkedError: error
        )

        let markdown = exporter.generateMarkdown(from: [network, error])

        #expect(markdown.contains("Error: `NSURLErrorDomain` code `-1009` (`notConnectedToInternet`) — NSURLError"))
        #expect(markdown.contains("Domain: `NSURLErrorDomain`"))
        #expect(markdown.contains("Code: `-1009` (`notConnectedToInternet`)"))
        #expect(markdown.contains("Failure Reason: The device is offline"))
        #expect(markdown.contains("Recovery Suggestion: Check the network connection"))
        #expect(markdown.contains("Underlying (1): NetworkExtension [7] Radio unavailable"))
        #expect(markdown.contains("`NSErrorFailingURLStringKey`: https://api.example.com/data"))
        #expect(markdown.contains("`operation`: fetchData"))
        #expect(markdown.contains("Linked Network Log: `\(networkID.uuidString)`"))
        #expect(markdown.contains("Source: `APIClient.swift:42 — fetchData()`"))
        #expect(markdown.contains("`0 ChronicleTests richErrorDiagnostics`"))
    }

}
