import Testing
import Foundation
@testable import Chronicle

@Suite("FlowTracker Tests")
struct FlowTrackerTests {
    private func makeStorage() throws -> SwiftDataStorage {
        try SwiftDataStorage.inMemory()
    }

    @Test("Track first screen")
    func trackFirstScreen() throws {
        let storage = try makeStorage()
        let tracker = FlowTracker(storage: storage)

        tracker.trackScreen("HomeScreen")

        let events = tracker.breadcrumbs()
        #expect(events.count == 1)
        #expect(events[0].from == nil)
        #expect(events[0].to.screenName == "HomeScreen")
        #expect(events[0].transitionType == .push)
        #expect(events[0].category == .flow)
    }

    @Test("Track screen transitions")
    func trackTransitions() throws {
        let storage = try makeStorage()
        let tracker = FlowTracker(storage: storage)

        tracker.trackScreen("HomeScreen")
        tracker.trackScreen("SettingsScreen", transition: .push)
        tracker.trackScreen("ProfileScreen", transition: .present)

        let events = tracker.breadcrumbs()
        #expect(events.count == 3)

        #expect(events[0].from == nil)
        #expect(events[0].to.screenName == "HomeScreen")

        #expect(events[1].from?.screenName == "HomeScreen")
        #expect(events[1].to.screenName == "SettingsScreen")
        #expect(events[1].transitionType == .push)

        #expect(events[2].from?.screenName == "SettingsScreen")
        #expect(events[2].to.screenName == "ProfileScreen")
        #expect(events[2].transitionType == .present)
    }

    @Test("Track screen with metadata")
    func trackScreenWithMetadata() throws {
        let storage = try makeStorage()
        let tracker = FlowTracker(storage: storage)

        tracker.trackScreen("ProductDetail", transition: .push, metadata: ["product_id": "abc123"])

        let events = tracker.breadcrumbs()
        #expect(events.count == 1)
        #expect(events[0].to.additionalInfo?["product_id"] == .string("abc123"))
    }

    @Test("Track lifecycle event")
    func trackLifecycle() throws {
        let storage = try makeStorage()
        let tracker = FlowTracker(storage: storage)

        tracker.trackScreen("HomeScreen")
        tracker.trackLifecycle(.didEnterBackground)

        let events = tracker.breadcrumbs()
        #expect(events.count == 2)
        #expect(events[1].to.screenName == "didEnterBackground")
        #expect(events[1].transitionType == .lifecycle)
    }

    @Test("Current screen tracking")
    func currentScreen() throws {
        let storage = try makeStorage()
        let tracker = FlowTracker(storage: storage)

        #expect(tracker.getCurrentScreen() == nil)

        tracker.trackScreen("HomeScreen")
        #expect(tracker.getCurrentScreen()?.screenName == "HomeScreen")

        tracker.trackScreen("Settings")
        #expect(tracker.getCurrentScreen()?.screenName == "Settings")
    }

    @Test("Breadcrumbs respects limit")
    func breadcrumbsLimit() throws {
        let storage = try makeStorage()
        let tracker = FlowTracker(storage: storage)

        for i in 0..<10 {
            tracker.trackScreen("Screen_\(i)")
        }

        let crumbs = tracker.breadcrumbs(limit: 3)
        #expect(crumbs.count == 3)
    }
}
