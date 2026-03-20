import Foundation

/// Tracks navigation flow and screen transitions in the app.
public final class FlowTracker: @unchecked Sendable {
    private let storage: SwiftDataStorage
    private var _currentStep: FlowStep?
    private let lock = NSLock()

    private var currentStep: FlowStep? {
        get { lock.withLock { _currentStep } }
        set { lock.withLock { _currentStep = newValue } }
    }

    init(storage: SwiftDataStorage) {
        self.storage = storage
    }

    /// Tracks a screen transition.
    public func trackScreen(
        _ name: String,
        transition: TransitionType = .push,
        metadata: EventMetadata? = nil
    ) {
        let previousStep = currentStep
        let newStep = FlowStep(
            screenName: name,
            transitionType: transition,
            additionalInfo: metadata
        )

        let flowEvent = FlowEvent(
            from: previousStep,
            to: newStep,
            transitionType: transition
        )

        currentStep = newStep
        storage.store(flowEvent)
    }

    /// Tracks an app lifecycle event.
    public func trackLifecycle(_ event: LifecycleEvent) {
        let step = FlowStep(
            screenName: event.rawValue,
            transitionType: .lifecycle
        )

        let flowEvent = FlowEvent(
            from: currentStep,
            to: step,
            transitionType: .lifecycle
        )

        storage.store(flowEvent)
    }

    /// The currently active screen.
    public func getCurrentScreen() -> FlowStep? {
        currentStep
    }

    /// Returns recent flow events (breadcrumbs), up to the specified limit.
    public func breadcrumbs(limit: Int = 50) -> [FlowEvent] {
        let query = StorageQuery(categories: [.flow], limit: limit)
        return storage.entries(matching: query).compactMap { $0 as? FlowEvent }
    }

    /// Returns all stored flow events.
    public func allFlowEvents() -> [FlowEvent] {
        let query = StorageQuery(categories: [.flow])
        return storage.entries(matching: query).compactMap { $0 as? FlowEvent }
    }
}
