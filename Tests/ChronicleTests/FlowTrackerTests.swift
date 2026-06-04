import Testing
import Foundation
@testable import Chronicle

@Suite("FlowTracker Tests")
struct FlowTrackerTests {
    private func makeTracker() throws -> (FlowTracker, StorageWriter) {
        let storage = try SwiftDataStorage.inMemory()
        let writer = StorageWriter(storage: storage)
        return (FlowTracker(storage: storage, writer: writer), writer)
    }

    @Test("Track first screen")
    func trackFirstScreen() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.trackScreen("HomeScreen")
        await writer.flush()

        let events = await tracker.breadcrumbs()
        #expect(events.count == 1)
        #expect(events[0].from == nil)
        #expect(events[0].to.screenName == "HomeScreen")
        #expect(events[0].transitionType == .push)
        #expect(events[0].category == .flow)
    }

    @Test("Track screen transitions")
    func trackTransitions() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.trackScreen("HomeScreen")
        tracker.trackScreen("SettingsScreen", transition: .push)
        tracker.trackScreen("ProfileScreen", transition: .present)
        await writer.flush()

        let events = await tracker.breadcrumbs()
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
    func trackScreenWithMetadata() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.trackScreen("ProductDetail", transition: .push, context: ["product_id": "abc123"])
        await writer.flush()

        let events = await tracker.breadcrumbs()
        #expect(events.count == 1)
        #expect(events[0].to.additionalInfo?["product_id"] == .string("abc123"))
    }

    @Test("Track lifecycle event")
    func trackLifecycle() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.trackScreen("HomeScreen")
        tracker.trackLifecycle(.didEnterBackground)
        await writer.flush()

        let events = await tracker.breadcrumbs()
        #expect(events.count == 2)
        #expect(events[1].to.screenName == "didEnterBackground")
        #expect(events[1].transitionType == .lifecycle)
    }

    @Test("Current screen tracking")
    func currentScreen() async throws {
        let (tracker, _) = try makeTracker()

        #expect(tracker.getCurrentScreen() == nil)

        tracker.trackScreen("HomeScreen")
        #expect(tracker.getCurrentScreen()?.screenName == "HomeScreen")

        tracker.trackScreen("Settings")
        #expect(tracker.getCurrentScreen()?.screenName == "Settings")
    }

    @Test("Breadcrumbs respects limit")
    func breadcrumbsLimit() async throws {
        let (tracker, writer) = try makeTracker()

        for i in 0..<10 {
            tracker.trackScreen("Screen_\(i)")
        }
        await writer.flush()

        let crumbs = await tracker.breadcrumbs(limit: 3)
        #expect(crumbs.count == 3)
    }
}
