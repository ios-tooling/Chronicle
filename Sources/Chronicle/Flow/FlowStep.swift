import Foundation

/// The type of navigation transition between screens.
public enum TransitionType: String, Codable, Sendable {
    case push
    case pop
    case present
    case dismiss
    case tab
    case deepLink
    case lifecycle
}

/// App lifecycle events that can be tracked.
public enum LifecycleEvent: String, Codable, Sendable {
    case didBecomeActive
    case willResignActive
    case didEnterBackground
    case willEnterForeground
    case didTerminate
}

/// Represents a single step in the app's navigation flow.
public struct FlowStep: Codable, Sendable, Hashable {
    /// The name of the screen or view.
    public let screenName: String

    /// How the user arrived at this screen.
    public let transitionType: TransitionType

    /// When this step occurred.
    public let timestamp: Date

    /// Additional context about this step.
    public let additionalInfo: EventMetadata?

    public init(
        screenName: String,
        transitionType: TransitionType = .push,
        timestamp: Date = Date(),
        additionalInfo: EventMetadata? = nil
    ) {
        self.screenName = screenName
        self.transitionType = transitionType
        self.timestamp = timestamp
        self.additionalInfo = additionalInfo
    }
}
