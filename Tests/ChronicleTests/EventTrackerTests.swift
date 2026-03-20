import Testing
import Foundation
@testable import Chronicle

@Suite("EventTracker Tests")
struct EventTrackerTests {
    private func makeStorage() throws -> SwiftDataStorage {
        try SwiftDataStorage.inMemory()
    }

    @Test("Track a simple event")
    func trackSimpleEvent() throws {
        let storage = try makeStorage()
        let tracker = EventTracker(storage: storage)

        tracker.track("button_tapped")

        let events = tracker.recentEvents()
        #expect(events.count == 1)
        #expect(events[0].name == "button_tapped")
        #expect(events[0].metadata == nil)
        #expect(events[0].category == .event)
    }

    @Test("Track event with metadata")
    func trackEventWithMetadata() throws {
        let storage = try makeStorage()
        let tracker = EventTracker(storage: storage)

        let metadata: EventMetadata = [
            "screen": "checkout",
            "item_count": 3,
            "total": 29.99
        ]
        tracker.track("purchase_completed", metadata: metadata)

        let events = tracker.recentEvents()
        #expect(events.count == 1)
        #expect(events[0].name == "purchase_completed")
        #expect(events[0].metadata?["screen"] == .string("checkout"))
        #expect(events[0].metadata?["item_count"] == .int(3))
        #expect(events[0].metadata?["total"] == .double(29.99))
    }

    @Test("Track multiple events")
    func trackMultipleEvents() throws {
        let storage = try makeStorage()
        let tracker = EventTracker(storage: storage)

        tracker.track("app_launched")
        tracker.track("screen_viewed", metadata: ["name": "home"])
        tracker.track("button_tapped", metadata: ["id": "settings"])

        let events = tracker.allEvents()
        #expect(events.count == 3)
    }

    @Test("Recent events respects limit")
    func recentEventsLimit() throws {
        let storage = try makeStorage()
        let tracker = EventTracker(storage: storage)

        for i in 0..<10 {
            tracker.track("event_\(i)")
        }

        let recent = tracker.recentEvents(limit: 3)
        #expect(recent.count == 3)
    }

    @Test("Event has correct properties")
    func eventProperties() throws {
        let now = Date()
        let event = Event(
            timestamp: now,
            name: "test_event",
            metadata: ["key": "value"]
        )

        #expect(event.category == .event)
        #expect(event.name == "test_event")
        #expect(event.timestamp == now)
        #expect(event.metadata?["key"] == .string("value"))
    }
}
