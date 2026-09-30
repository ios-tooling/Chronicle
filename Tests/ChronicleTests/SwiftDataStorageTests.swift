import Testing
import Foundation
@testable import Chronicle

@Suite("SwiftDataStorage Tests")
struct SwiftDataStorageTests {
    private func makeStorage() throws -> SwiftDataStorage {
        try SwiftDataStorage.inMemory()
    }

    @Test("Store and retrieve an event")
    func storeAndRetrieveEvent() async throws {
        let storage = try makeStorage()

        let event = Event(name: "test_event", context: ["key": "value"])
        await storage.store(event)

        let entries = await storage.allEntries()
        #expect(entries.count == 1)

        let retrieved = entries[0] as? Event
        #expect(retrieved != nil)
        #expect(retrieved?.name == "test_event")
        #expect(retrieved?.context?["key"] == .string("value"))
    }

    @Test("Store and retrieve a network log")
    func storeAndRetrieveNetworkLog() async throws {
        let storage = try makeStorage()

        let log = NetworkLog(
            url: URL(string: "https://example.com")!,
            method: "GET",
            statusCode: 200,
            metrics: NetworkMetrics(
                startTime: Date(),
                endTime: Date().addingTimeInterval(1),
                bytesSent: 50,
                bytesReceived: 1024
            )
        )
        await storage.store(log)

        let entries = await storage.entries(matching: StorageQuery(categories: [.network]))
        #expect(entries.count == 1)

        let retrieved = entries[0] as? NetworkLog
        #expect(retrieved?.method == "GET")
        #expect(retrieved?.statusCode == 200)
    }

    @Test("A size kept without its body survives storage and reads bracketed")
    func storeAndRetrieveSizeWithoutBody() async throws {
        let storage = try makeStorage()

        let log = NetworkLog(
            url: URL(string: "https://example.com")!,
            method: "GET",
            statusCode: 200,
            responseBodySize: 2048,
            metrics: NetworkMetrics(startTime: Date(), endTime: Date(), bytesSent: 0, bytesReceived: 2048)
        )
        await storage.store(log)

        let retrieved = await storage.entries(matching: StorageQuery(categories: [.network])).first as? NetworkLog
        #expect(retrieved?.responseBody == nil)
        #expect(retrieved?.responseBodySize == 2048)
        #expect(NetworkLog.sizeText(2048, bodyRecorded: false) == "[2 KB]")
        #expect(NetworkLog.sizeText(2048, bodyRecorded: true) == "2 KB")
    }

    @Test("Store and retrieve a flow event")
    func storeAndRetrieveFlowEvent() async throws {
        let storage = try makeStorage()

        let from = FlowStep(screenName: "Home", transitionType: .push)
        let to = FlowStep(screenName: "Settings", transitionType: .push)
        let flowEvent = FlowEvent(from: from, to: to, transitionType: .push)
        await storage.store(flowEvent)

        let entries = await storage.entries(matching: StorageQuery(categories: [.flow]))
        #expect(entries.count == 1)

        let retrieved = entries[0] as? FlowEvent
        #expect(retrieved?.from?.screenName == "Home")
        #expect(retrieved?.to.screenName == "Settings")
    }

    @Test("Query with date range")
    func queryDateRange() async throws {
        let storage = try makeStorage()

        let old = Event(timestamp: Date().addingTimeInterval(-3600), name: "old_event")
        let recent = Event(name: "recent_event")
        await storage.store(old)
        await storage.store(recent)

        let query = StorageQuery(since: Date().addingTimeInterval(-60))
        let results = await storage.entries(matching: query)
        #expect(results.count == 1)
        #expect((results[0] as? Event)?.name == "recent_event")
    }

    @Test("Query with category filter")
    func queryCategoryFilter() async throws {
        let storage = try makeStorage()

        await storage.store(Event(name: "an_event"))
        await storage.store(NetworkLog(
            url: URL(string: "https://example.com")!,
            method: "GET"
        ))

        let eventQuery = StorageQuery(categories: [.event])
        let eventResults = await storage.entries(matching: eventQuery)
        #expect(eventResults.count == 1)
        #expect(eventResults[0].category == .event)

        let networkQuery = StorageQuery(categories: [.network])
        let networkResults = await storage.entries(matching: networkQuery)
        #expect(networkResults.count == 1)
        #expect(networkResults[0].category == .network)
    }

    @Test("Query with limit")
    func queryWithLimit() async throws {
        let storage = try makeStorage()

        for i in 0..<10 {
            await storage.store(Event(name: "event_\(i)"))
        }

        let query = StorageQuery(limit: 3)
        let results = await storage.entries(matching: query)
        #expect(results.count == 3)
    }

    @Test("Clear all entries")
    func clearAll() async throws {
        let storage = try makeStorage()

        await storage.store(Event(name: "event"))
        await storage.store(NetworkLog(url: URL(string: "https://example.com")!, method: "GET"))

        #expect(await storage.allEntries().count == 2)

        await storage.clear()
        #expect(await storage.allEntries().count == 0)
    }

    @Test("Clear entries before date")
    func clearBeforeDate() async throws {
        let storage = try makeStorage()

        let old = Event(timestamp: Date().addingTimeInterval(-3600), name: "old")
        let recent = Event(name: "recent")
        await storage.store(old)
        await storage.store(recent)

        await storage.clear(before: Date().addingTimeInterval(-60))

        let entries = await storage.allEntries()
        #expect(entries.count == 1)
        #expect((entries[0] as? Event)?.name == "recent")
    }

    @Test("Query with name filter")
    func queryNameFilter() async throws {
        let storage = try makeStorage()

        await storage.store(Event(name: "user_login"))
        await storage.store(Event(name: "user_logout"))
        await storage.store(Event(name: "page_view"))

        let query = StorageQuery(categories: [.event], nameContains: "user")
        let results = await storage.entries(matching: query)
        #expect(results.count == 2)
    }
}
