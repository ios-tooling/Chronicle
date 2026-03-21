import Testing
import Foundation
@testable import Chronicle

@Suite("NetworkLogger Tests")
struct NetworkLoggerTests {
    private func makeStorage() throws -> SwiftDataStorage {
        try SwiftDataStorage.inMemory()
    }

    @Test("Log a network request")
    func logNetworkRequest() throws {
        let storage = try makeStorage()
        let logger = NetworkLogger(storage: storage)

        let url = URL(string: "https://api.example.com/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let startTime = Date()

        logger.log(
            request: request,
            startTime: startTime,
            endTime: startTime.addingTimeInterval(0.5)
        )

        let logs = logger.recentLogs()
        #expect(logs.count == 1)
        #expect(logs[0].url == url)
        #expect(logs[0].method == "GET")
        #expect(logs[0].category == .network)
    }

    @Test("Log request with response")
    func logWithResponse() throws {
        let storage = try makeStorage()
        let logger = NetworkLogger(storage: storage)

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

        let logs = logger.recentLogs()
        #expect(logs.count == 1)
        #expect(logs[0].method == "POST")
        #expect(logs[0].statusCode == 200)
        #expect(logs[0].requestBodySize == 9)
        #expect(logs[0].responseBodySize == 11)
    }

    @Test("Log request with error")
    func logWithError() throws {
        let storage = try makeStorage()
        let logger = NetworkLogger(storage: storage)

        let url = URL(string: "https://api.example.com/fail")!
        let request = URLRequest(url: url)
        let error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection failed"])

        logger.log(request: request, error: error)

        let logs = logger.recentLogs()
        #expect(logs.count == 1)
        #expect(logs[0].error == "Connection failed")
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
    func recentLogsLimit() throws {
        let storage = try makeStorage()
        let logger = NetworkLogger(storage: storage)

        for i in 0..<5 {
            let url = URL(string: "https://api.example.com/\(i)")!
            let request = URLRequest(url: url)
            logger.log(request: request)
        }

        let logs = logger.recentLogs(limit: 2)
        #expect(logs.count == 2)
    }
}
