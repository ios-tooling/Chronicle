import Foundation

/// Timing and size metrics for a network request.
public struct NetworkMetrics: Codable, Sendable, Hashable {
    /// When the request started.
    public let startTime: Date

    /// When the response completed.
    public let endTime: Date?

    /// Total bytes sent in the request.
    public let bytesSent: Int64

    /// Total bytes received in the response.
    public let bytesReceived: Int64

    /// Duration of the request in seconds, if completed.
    public var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    public init(startTime: Date = Date(), endTime: Date? = nil, bytesSent: Int64 = 0, bytesReceived: Int64 = 0) {
        self.startTime = startTime
        self.endTime = endTime
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
    }
}
