import Foundation

/// Identifies a logged request by the two facts a caller still has once the response is back:
/// the URL it was sent to and the moment it started (`NetworkMetrics.startTime`). Query and
/// fragment are ignored when matching, because loggers may strip them from the recorded URL.
public struct NetworkLogReference: Hashable, Sendable, Codable {
	public let url: URL
	public let startedAt: Date

	public init(url: URL, startedAt: Date) {
		self.url = url
		self.startedAt = startedAt
	}
}

/// An error raised on behalf of a logged network request. When one reaches `Chronicle.error`,
/// it is attached to that request's `NetworkLog` instead of being recorded as a separate
/// `ErrorLog`; if the request can't be found, the error is logged on its own.
public protocol NetworkLogLinkedError: Error {
	var networkLogReference: NetworkLogReference? { get }
}

extension URL {
	/// The URL without its query and fragment, for comparing a recorded URL against a live one.
	var chronicle_withoutQuery: String {
		guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return absoluteString }
		components.query = nil
		components.fragment = nil
		return components.url?.absoluteString ?? absoluteString
	}
}
