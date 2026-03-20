import Testing
import Foundation
@testable import Chronicle

@Suite("SwiftDataStorage Tests")
struct SwiftDataStorageTests {
    private func makeStorage() throws -> SwiftDataStorage {
        try SwiftDataStorage.inMemory()
    }

    @Test("Store and retrieve an event")
    func storeAndRetrieveEvent() throws {
        let storage = try makeStorage()

        let event = Event(name: "test_event", metadata: ["key": "value"])
        storage.store(event)

        let entries = storage.allEntries()
        #expect(entries.count == 1)

        let retrieved = entries[0] as? Event
        #expect(retrieved != nil)
        #expect(retrieved?.name == "test_event")
        #expect(retrieved?.metadata?["key"] == .string("value"))
    }

    @Test("Store and retrieve a network log")
    func storeAndRetrieveNetworkLog() throws {
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
        storage.store(log)

        let entries = storage.entries(matching: StorageQuery(categories: [.network]))
        #expect(entries.count == 1)

        let retrieved = entries[0] as? NetworkLog
        #expect(retrieved?.method == "GET")
        #expect(retrieved?.statusCode == 200)
    }

    @Test("Store and retrieve a flow event")
    func storeAndRetrieveFlowEvent() throws {
        let storage = try makeStorage()

        let from = FlowStep(screenName: "Home", transitionType: .push)
        let to = FlowStep(screenName: "Settings", transitionType: .push)
        let flowEvent = FlowEvent(from: from, to: to, transitionType: .push)
        storage.store(flowEvent)

        let entries = storage.entries(matching: StorageQuery(categories: [.flow]))
        #expect(entries.count == 1)

        let retrieved = entries[0] as? FlowEvent
        #expect(retrieved?.from?.screenName == "Home")
        #expect(retrieved?.to.screenName == "Settings")
    }

    @Test("Query with date range")
    func queryDateRange() throws {
        let storage = try makeStorage()

        let old = Event(timestamp: Date().addingTimeInterval(-3600), name: "old_event")
        let recent = Event(name: "recent_event")
        storage.store(old)
        storage.store(recent)

        let query = StorageQuery(since: Date().addingTimeInterval(-60))
        let results = storage.entries(matching: query)
        #expect(results.count == 1)
        #expect((results[0] as? Event)?.name == "recent_event")
    }

    @Test("Query with category filter")
    func queryCategoryFilter() throws {
        let storage = try makeStorage()

        storage.store(Event(name: "an_event"))
        storage.store(NetworkLog(
            url: URL(string: "https://example.com")!,
            method: "GET"
        ))

        let eventQuery = StorageQuery(categories: [.event])
        let eventResults = storage.entries(matching: eventQuery)
        #expect(eventResults.count == 1)
        #expect(eventResults[0].category == .event)

        let networkQuery = StorageQuery(categories: [.network])
        let networkResults = storage.entries(matching: networkQuery)
        #expect(networkResults.count == 1)
        #expect(networkResults[0].category == .network)
    }

    @Test("Query with limit")
    func queryWithLimit() throws {
        let storage = try makeStorage()

        for i in 0..<10 {
            storage.store(Event(name: "event_\(i)"))
        }

        let query = StorageQuery(limit: 3)
        let results = storage.entries(matching: query)
        #expect(results.count == 3)
    }

    @Test("Clear all entries")
    func clearAll() throws {
        let storage = try makeStorage()

        storage.store(Event(name: "event"))
        storage.store(NetworkLog(url: URL(string: "https://example.com")!, method: "GET"))

        #expect(storage.allEntries().count == 2)

        storage.clear()
        #expect(storage.allEntries().count == 0)
    }

    @Test("Clear entries before date")
    func clearBeforeDate() throws {
        let storage = try makeStorage()

        let old = Event(timestamp: Date().addingTimeInterval(-3600), name: "old")
        let recent = Event(name: "recent")
        storage.store(old)
        storage.store(recent)

        storage.clear(before: Date().addingTimeInterval(-60))

        let entries = storage.allEntries()
        #expect(entries.count == 1)
        #expect((entries[0] as? Event)?.name == "recent")
    }

    @Test("Query with name filter")
    func queryNameFilter() throws {
        let storage = try makeStorage()

        storage.store(Event(name: "user_login"))
        storage.store(Event(name: "user_logout"))
        storage.store(Event(name: "page_view"))

        let query = StorageQuery(categories: [.event], nameContains: "user")
        let results = storage.entries(matching: query)
        #expect(results.count == 2)
    }
}
