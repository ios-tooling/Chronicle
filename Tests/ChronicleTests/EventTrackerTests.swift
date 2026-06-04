import Testing
import Foundation
@testable import Chronicle

@Suite("EventTracker Tests")
struct EventTrackerTests {
    private func makeTracker() throws -> (EventTracker, StorageWriter) {
        let storage = try SwiftDataStorage.inMemory()
        let writer = StorageWriter(storage: storage)
        return (EventTracker(storage: storage, writer: writer), writer)
    }

    @Test("Track a simple event")
    func trackSimpleEvent() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.track("button_tapped")
        await writer.flush()

        let events = await tracker.recentEvents()
        #expect(events.count == 1)
        #expect(events[0].name == "button_tapped")
        #expect(events[0].context == nil)
        #expect(events[0].category == .event)
    }

    @Test("Track event with metadata")
    func trackEventWithMetadata() async throws {
        let (tracker, writer) = try makeTracker()

        let context: EventMetadata = [
            "screen": "checkout",
            "item_count": 3,
            "total": 29.99
        ]
        tracker.track("purchase_completed", context: context)
        await writer.flush()

        let events = await tracker.recentEvents()
        #expect(events.count == 1)
        #expect(events[0].name == "purchase_completed")
        #expect(events[0].context?["screen"] == .string("checkout"))
        #expect(events[0].context?["item_count"] == .int(3))
        #expect(events[0].context?["total"] == .double(29.99))
    }

    @Test("Track multiple events")
    func trackMultipleEvents() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.track("app_launched")
        tracker.track("screen_viewed", context: ["name": "home"])
        tracker.track("button_tapped", context: ["id": "settings"])
        await writer.flush()

        let events = await tracker.allEvents()
        #expect(events.count == 3)
    }

    @Test("Recent events respects limit")
    func recentEventsLimit() async throws {
        let (tracker, writer) = try makeTracker()

        for i in 0..<10 {
            tracker.track("event_\(i)")
        }
        await writer.flush()

        let recent = await tracker.recentEvents(limit: 3)
        #expect(recent.count == 3)
    }

    @Test("Event has correct properties")
    func eventProperties() throws {
        let now = Date()
        let event = Event(
            timestamp: now,
            name: "test_event",
            context: ["key": "value"]
        )

        #expect(event.category == .event)
        #expect(event.name == "test_event")
        #expect(event.timestamp == now)
        #expect(event.context?["key"] == .string("value"))
    }
}
