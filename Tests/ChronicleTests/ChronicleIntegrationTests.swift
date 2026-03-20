import Testing
import Foundation
@testable import Chronicle

@Suite("Chronicle Integration Tests")
struct ChronicleIntegrationTests {
    @Test("Full lifecycle: configure, track, query, report")
    func fullLifecycle() throws {
        let chronicle = Chronicle.shared
        try chronicle.configureInMemory()

        // Track events
        chronicle.events.track("app_launched")
        chronicle.events.track("screen_viewed", metadata: ["name": "home"])

        // Log network
        let url = URL(string: "https://api.example.com/config")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        chronicle.network.log(request: request)

        // Track flow
        chronicle.flow.trackScreen("HomeScreen")
        chronicle.flow.trackScreen("SettingsScreen", transition: .push)

        // Query all entries
        let allEntries = chronicle.allEntries()
        #expect(allEntries.count == 5) // 2 events + 1 network + 2 flow

        // Query by category
        let eventEntries = chronicle.entries(matching: StorageQuery(categories: [.event]))
        #expect(eventEntries.count == 2)

        let networkEntries = chronicle.entries(matching: StorageQuery(categories: [.network]))
        #expect(networkEntries.count == 1)

        let flowEntries = chronicle.entries(matching: StorageQuery(categories: [.flow]))
        #expect(flowEntries.count == 2)

        // Generate report
        let report = try chronicle.generateReport(title: "Integration Test Report")
        #expect(report.contains("# Integration Test Report"))
        #expect(report.contains("app_launched"))
        #expect(report.contains("api.example.com"))
        #expect(report.contains("HomeScreen"))
        #expect(report.contains("SettingsScreen"))

        // Clear
        chronicle.clear()
        #expect(chronicle.allEntries().count == 0)
    }

    @Test("AnyCodableValue roundtrip encoding")
    func anyCodableValueRoundtrip() throws {
        let values: [String: AnyCodableValue] = [
            "string": .string("hello"),
            "int": .int(42),
            "double": .double(3.14),
            "bool": .bool(true),
            "date": .date(Date(timeIntervalSince1970: 1000000))
        ]

        let data = try JSONEncoder().encode(values)
        let decoded = try JSONDecoder().decode([String: AnyCodableValue].self, from: data)

        #expect(decoded["string"] == .string("hello"))
        #expect(decoded["int"] == .int(42))
        #expect(decoded["double"] == .double(3.14))
        #expect(decoded["bool"] == .bool(true))
        #expect(decoded["date"] == .date(Date(timeIntervalSince1970: 1000000)))
    }

    @Test("EventMetadata dictionary literal")
    func eventMetadataLiteral() {
        let metadata: EventMetadata = [
            "name": "test",
            "count": 5,
            "ratio": 0.75,
            "active": true
        ]

        #expect(metadata["name"] == .string("test"))
        #expect(metadata["count"] == .int(5))
        #expect(metadata["ratio"] == .double(0.75))
        #expect(metadata["active"] == .bool(true))
        #expect(metadata.count == 4)
        #expect(!metadata.isEmpty)
    }
}
