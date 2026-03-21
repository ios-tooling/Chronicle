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
        #expect(markdown.contains("## Events"))
        #expect(markdown.contains("## Network"))
        #expect(markdown.contains("## Flow"))
        #expect(markdown.contains("## Errors"))
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
        #expect(markdown.contains("Network Error Rate"))
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

    @Test("Network error rate calculation")
    func networkErrorRate() throws {
        let exporter = MarkdownExporter()

        let entries: [any ChronicleEntry] = [
            NetworkLog(url: URL(string: "https://a.com")!, method: "GET", statusCode: 200,
                      metrics: NetworkMetrics(startTime: Date(), endTime: Date())),
            NetworkLog(url: URL(string: "https://b.com")!, method: "GET", statusCode: 404,
                      metrics: NetworkMetrics(startTime: Date(), endTime: Date())),
            NetworkLog(url: URL(string: "https://c.com")!, method: "GET", statusCode: 500,
                      metrics: NetworkMetrics(startTime: Date(), endTime: Date())),
            NetworkLog(url: URL(string: "https://d.com")!, method: "GET", statusCode: 200,
                      metrics: NetworkMetrics(startTime: Date(), endTime: Date()))
        ]

        let markdown = exporter.generateMarkdown(from: entries)
        // 2 out of 4 requests had errors (404 and 500)
        #expect(markdown.contains("50.0%"))
    }
}
