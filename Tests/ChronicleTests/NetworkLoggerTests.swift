import Testing
import Foundation
@testable import Chronicle

@Suite("NetworkLogger Tests")
struct NetworkLoggerTests {
    private func makeLogger() throws -> (NetworkLogger, StorageWriter) {
        let storage = try SwiftDataStorage.inMemory()
        let writer = StorageWriter(storage: storage)
        return (NetworkLogger(storage: storage, writer: writer), writer)
    }

    @Test("Log a network request")
    func logNetworkRequest() async throws {
        let (logger, writer) = try makeLogger()

        let url = URL(string: "https://api.example.com/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let startTime = Date()

        logger.log(
            request: request,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(0.5)
        )
        await writer.flush()

        let logs = await logger.recentLogs()
        #expect(logs.count == 1)
        #expect(logs[0].url == url)
        #expect(logs[0].method == "GET")
        #expect(logs[0].category == .network)
    }

    @Test("Log request with response")
    func logWithResponse() async throws {
        let (logger, writer) = try makeLogger()

        let url = URL(string: "https://api.example.com/data")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "test body".data(using: .utf8)

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )

        let responseData = "{\"ok\":true}".data(using: .utf8)

        logger.log(
            request: request,
            response: response,
            data: responseData
        )
        await writer.flush()

        let logs = await logger.recentLogs()
        #expect(logs.count == 1)
        #expect(logs[0].method == "POST")
        #expect(logs[0].statusCode == 200)
        #expect(logs[0].requestBodySize == 9)
        #expect(logs[0].responseBodySize == 11)
    }

    @Test("Log request with error")
    func logWithError() async throws {
        let (logger, writer) = try makeLogger()

        let url = URL(string: "https://api.example.com/fail")!
        let request = URLRequest(url: url)
        let error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])

        logger.log(request: request, error: error)
        await writer.flush()

        let logs = await logger.recentLogs()
        #expect(logs.count == 1)
        #expect(logs[0].error?.contains("test [-1]") == true)
        #expect(logs[0].error?.contains("Connection failed") == true)
    }

    @Test("Custom metrics preserve a richly linked network error")
    func customMetricsPreserveLinkedError() async throws {
        let storage = try SwiftDataStorage.inMemory()
        let writer = StorageWriter(storage: storage)
        let errorTracker = ErrorTracker(storage: storage, writer: writer)
        let logger = NetworkLogger(storage: storage, writer: writer, errorTracker: errorTracker)

        let url = URL(string: "https://api.example.com/offline")!
        let request = URLRequest(url: url)
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "NSURLError"]
        )
        let start = Date()
        let metrics = NetworkMetrics(startTime: start, endTime: start.addingTimeInterval(0.25))

        logger.log(request: request, error: error, metrics: metrics)
        await writer.flush()

        let entries = await storage.allEntries()
        let networkLog = try #require(entries.compactMap { $0 as? NetworkLog }.first)
        let errorLog = try #require(entries.compactMap { $0 as? ErrorLog }.first)

        #expect(networkLog.metrics == metrics)
        #expect(networkLog.linkedErrorID == errorLog.id)
        #expect(errorLog.linkedNetworkLogID == networkLog.id)
        #expect(networkLog.error?.contains("NSURLErrorDomain [-1009, notConnectedToInternet]") == true)
    }

    @Test("NetworkMetrics duration calculation")
    func metricsDuration() {
        let start = Date()
        let end = start.addingTimeInterval(1.5)
        let metrics = NetworkMetrics(startTime: start, endTime: end, bytesSent: 100, bytesReceived: 500)

        #expect(metrics.duration != nil)
        #expect(abs(metrics.duration! - 1.5) < 0.001)
        #expect(metrics.bytesSent == 100)
        #expect(metrics.bytesReceived == 500)
    }

    @Test("NetworkMetrics nil duration when no end time")
    func metricsNilDuration() {
        let metrics = NetworkMetrics(startTime: Date())
        #expect(metrics.duration == nil)
    }

    @Test("Recent logs respects limit")
    func recentLogsLimit() async throws {
        let (logger, writer) = try makeLogger()

        for i in 0..<5 {
            let url = URL(string: "https://api.example.com/\(i)")!
            let request = URLRequest(url: url)
            logger.log(request: request)
        }
        await writer.flush()

        let logs = await logger.recentLogs(limit: 2)
        #expect(logs.count == 2)
    }
}
