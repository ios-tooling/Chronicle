import Foundation
import os

/// Exports Chronicle entries to the console using os.Logger.
public struct ConsoleExporter: ExportDestination {
    private static let logger = Logger(subsystem: "com.chronicle", category: "export")

    public init() {}

    @discardableResult
    public func export(_ entries: [any ChronicleEntry]) throws -> Data? {
        for entry in entries {
            let message = format(entry)
            Self.logger.info("\(message)")
        }
        return nil
    }

    private func format(_ entry: any ChronicleEntry) -> String {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: entry.timestamp)

        switch entry {
        case let event as Event:
            var message = "[\(timestamp)] EVENT: \(event.name)"
            if let metadata = event.metadata, !metadata.isEmpty {
                message += " \(metadata)"
            }
            return message

        case let networkLog as NetworkLog:
            var message = "[\(timestamp)] NETWORK: \(networkLog.method) \(networkLog.url.absoluteString)"
            if let status = networkLog.statusCode {
                message += " → \(status)"
            }
            if let duration = networkLog.metrics.duration {
                message += " (\(String(format: "%.2f", duration))s)"
            }
            if let error = networkLog.error {
                message += " ERROR: \(error)"
            }
            return message

        case let flowEvent as FlowEvent:
            var message = "[\(timestamp)] FLOW: "
            if let from = flowEvent.from {
                message += "\(from.screenName) → "
            }
            message += "\(flowEvent.to.screenName) (\(flowEvent.transitionType.rawValue))"
            return message

        case let errorLog as ErrorLog:
            var message = "[\(timestamp)] ERROR [\(errorLog.severity.rawValue.uppercased())]: \(errorLog.errorType)"
            message += " — \(errorLog.message)"
            if let code = errorLog.code {
                message += " (domain: \(errorLog.domain), code: \(code))"
            }
            if let reason = errorLog.failureReason {
                message += " Reason: \(reason)"
            }
            return message

        default:
            return "[\(timestamp)] \(entry.category.rawValue.uppercased()): \(entry.id)"
        }
    }
}
