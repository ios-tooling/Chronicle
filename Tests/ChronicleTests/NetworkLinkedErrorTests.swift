import Testing
import Foundation
@testable import Chronicle

/// Stands in for an error a caller raises after a request came back, e.g. an empty envelope.
private struct RequestFailure: NetworkLogLinkedError, LocalizedError {
    let networkLogReference: NetworkLogReference?
    var errorDescription: String? { "The server returned an incomplete response." }
}

@Suite("Network-linked errors")
struct NetworkLinkedErrorTests {
    private func makeTrackers() throws -> (NetworkLogger, ErrorTracker, StorageWriter) {
        let storage = try SwiftDataStorage.inMemory()
        let writer = StorageWriter(storage: storage)
        let errors = ErrorTracker(storage: storage, writer: writer)
        return (NetworkLogger(storage: storage, writer: writer, errorTracker: errors), errors, writer)
    }

    private func logRequest(_ network: NetworkLogger, url: URL, statusCode: Int = 200, startedAt: Date) {
        let metrics = NetworkMetrics(startTime: startedAt, endTime: startedAt.addingTimeInterval(0.3))
        network.log(NetworkLog(url: url, method: "GET", statusCode: statusCode, metrics: metrics))
    }

    @Test("An error raised for a logged request is attached to it instead of logged separately")
    func attachesToMatchingRequest() async throws {
        let (network, errors, writer) = try makeTrackers()
        let startedAt = Date()
        // the logger stripped the query from the recorded URL; the caller still has the full one
        logRequest(network, url: URL(string: "https://api.example.com/v2/mood/responses/self")!, statusCode: 404, startedAt: startedAt)
        let sent = URL(string: "https://api.example.com/v2/mood/responses/self?start=2026-09-01")!

        errors.log(RequestFailure(networkLogReference: NetworkLogReference(url: sent, startedAt: startedAt)), context: ["context": .string("Failed to update historical moods")])
        await writer.flush()

        let standalone = await errors.recentErrors()
        #expect(standalone.isEmpty)

        let logs = await network.recentLogs()
        #expect(logs.count == 1)
        let linked = try #require(logs.first?.linkedError)
        #expect(linked.errorType == "RequestFailure")
        #expect(linked.message == "The server returned an incomplete response.")
        #expect(linked.context?["context"] == .string("Failed to update historical moods"))
        #expect(linked.linkedNetworkLogID == logs.first?.id)
    }

    @Test("A request that was never logged leaves the error standing on its own")
    func fallsBackToStandaloneError() async throws {
        let (network, errors, writer) = try makeTrackers()
        let url = URL(string: "https://api.example.com/v2/notifications")!
        logRequest(network, url: url, startedAt: Date())

        errors.log(RequestFailure(networkLogReference: NetworkLogReference(url: url, startedAt: Date().addingTimeInterval(-60))))
        await writer.flush()

        let standalone = await errors.recentErrors()
        #expect(standalone.count == 1)
        #expect(standalone.first?.errorType == "RequestFailure")
        let logs = await network.recentLogs()
        #expect(logs.first?.linkedError == nil)
    }

    @Test("A different URL at the same start time is not a match")
    func differentURLIsNotAMatch() async throws {
        let (network, errors, writer) = try makeTrackers()
        let startedAt = Date()
        logRequest(network, url: URL(string: "https://api.example.com/v2/notifications")!, startedAt: startedAt)

        errors.log(RequestFailure(networkLogReference: NetworkLogReference(url: URL(string: "https://api.example.com/v2/feed")!, startedAt: startedAt)))
        await writer.flush()

        let standalone = await errors.recentErrors()
        #expect(standalone.count == 1)
        let logs = await network.recentLogs()
        #expect(logs.first?.linkedError == nil)
    }

    @Test("A linked error without a reference is logged like any other")
    func missingReferenceLogsNormally() async throws {
        let (_, errors, writer) = try makeTrackers()

        errors.log(RequestFailure(networkLogReference: nil))
        await writer.flush()

        let standalone = await errors.recentErrors()
        #expect(standalone.count == 1)
    }
}
