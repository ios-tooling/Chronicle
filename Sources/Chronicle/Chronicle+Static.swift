import Foundation

@available(iOS 17, macOS 14, *)
extension Chronicle {

    /// Tracks a named event with optional metadata.
    nonisolated public static func track(_ name: String, metadata: EventMetadata? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        instance.events.track(name, metadata: metadata, file: file, function: function, line: line)
    }

    /// Logs a network request and response.
    nonisolated public static func network(
        request: URLRequest,
        response: HTTPURLResponse? = nil,
        data: Data? = nil,
        error: Error? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        instance.network.log(
            request: request,
            response: response,
            data: data,
            error: error,
            startTime: startTime,
            endTime: endTime,
            file: file,
            function: function,
            line: line
        )
    }

    /// Tracks a screen transition in the app flow.
    nonisolated public static func flow(_ name: String, transition: TransitionType = .push, metadata: EventMetadata? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        instance.flow.trackScreen(name, transition: transition, metadata: metadata, file: file, function: function, line: line)
    }

    /// Logs an error with optional severity and context.
    nonisolated public static func error(
        _ error: Error,
        severity: ErrorSeverity = .error,
        context: EventMetadata? = nil,
        captureCallStack: Bool = false,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        instance.errors.log(
            error,
            severity: severity,
            context: context,
            captureCallStack: captureCallStack,
            file: file,
            function: function,
            line: line
        )
    }

    /// Logs an error with a string context.
    nonisolated public static func error(_ error: Error, severity: ErrorSeverity = .error, context: String, captureCallStack: Bool = false, file: String = #file, function: String = #function, line: Int = #line) {
        let metadata: EventMetadata = ["context": .string(context)]
        self.error(error, severity: severity, context: metadata, captureCallStack: captureCallStack, file: file, function: function, line: line)
    }
}
