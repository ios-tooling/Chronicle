import Testing
import Foundation
@testable import Chronicle

// Test error types
enum TestError: Error, LocalizedError {
    case simple
    case withMessage(String)
    case nested(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .simple:
            return "A simple test error"
        case .withMessage(let message):
            return message
        case .nested(let underlying):
            return "Nested error: \(underlying.localizedDescription)"
        }
    }

    var failureReason: String? {
        switch self {
        case .simple:
            return "Something went wrong"
        case .withMessage:
            return nil
        case .nested:
            return "An underlying error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .simple:
            return "Try again"
        case .withMessage, .nested:
            return nil
        }
    }
}

@Suite("ErrorTracker Tests")
struct ErrorTrackerTests {
    private func makeTracker() throws -> (ErrorTracker, StorageWriter) {
        let storage = try SwiftDataStorage.inMemory()
        let writer = StorageWriter(storage: storage)
        return (ErrorTracker(storage: storage, writer: writer), writer)
    }

    @Test("Log a simple error")
    func logSimpleError() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.log(TestError.simple)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].category == .error)
        #expect(errors[0].message == "A simple test error")
        #expect(errors[0].errorType == "TestError")
        #expect(errors[0].severity == .error)
    }

    @Test("Log error with custom severity")
    func logErrorWithSeverity() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.log(TestError.simple, severity: .critical)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].severity == .critical)
    }

    @Test("Log error with context")
    func logErrorWithContext() async throws {
        let (tracker, writer) = try makeTracker()

        let context: EventMetadata = ["screen": "checkout", "userId": "user123"]
        tracker.log(TestError.simple, context: context)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].context?["screen"] == .string("checkout"))
        #expect(errors[0].context?["userId"] == .string("user123"))
        // Source location is captured in the ErrorLog's dedicated fields
        #expect(errors[0].sourceFunction != nil)
        #expect(errors[0].sourceLine != nil)
    }

    @Test("Log NSError with domain and code")
    func logNSError() async throws {
        let (tracker, writer) = try makeTracker()

        let nsError = NSError(
            domain: "com.myapp.database",
            code: 42,
            userInfo: [
                NSLocalizedDescriptionKey: "Database connection failed",
                NSLocalizedFailureReasonErrorKey: "Server unreachable",
                NSLocalizedRecoverySuggestionErrorKey: "Check network connection",
                "customKey": "customValue"
            ]
        )

        tracker.log(nsError)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].domain == "com.myapp.database")
        #expect(errors[0].code == 42)
        #expect(errors[0].message == "Database connection failed")
        #expect(errors[0].failureReason == "Server unreachable")
        #expect(errors[0].recoverySuggestion == "Check network connection")
        #expect(errors[0].userInfo?["customKey"] == "customValue")
    }

    @Test("Log error extracts failure reason and recovery suggestion")
    func logErrorExtractsLocalizedInfo() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.log(TestError.simple)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].failureReason == "Something went wrong")
        #expect(errors[0].recoverySuggestion == "Try again")
    }

    @Test("Full description includes error chain")
    func fullDescriptionIncludesChain() async throws {
        let (tracker, writer) = try makeTracker()

        let underlying = NSError(
            domain: "com.myapp.network",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Connection timeout"]
        )
        let outerError = NSError(
            domain: "com.myapp.api",
            code: 500,
            userInfo: [
                NSLocalizedDescriptionKey: "API call failed",
                NSUnderlyingErrorKey: underlying
            ]
        )

        tracker.log(outerError)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].fullDescription.contains("API call failed"))
        #expect(errors[0].fullDescription.contains("Underlying"))
        #expect(errors[0].fullDescription.contains("Connection timeout"))
    }

    @Test("Log multiple errors with different severities")
    func logMultipleErrors() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.log(TestError.simple, severity: .warning)
        tracker.log(TestError.withMessage("Critical failure"), severity: .critical)
        tracker.log(TestError.simple, severity: .info)
        await writer.flush()

        let allErrors = await tracker.allErrors()
        #expect(allErrors.count == 3)

        let criticalErrors = await tracker.errors(withSeverity: .critical)
        #expect(criticalErrors.count == 1)
        #expect(criticalErrors[0].message == "Critical failure")

        let warningErrors = await tracker.errors(withSeverity: .warning)
        #expect(warningErrors.count == 1)
    }

    @Test("Recent errors respects limit")
    func recentErrorsLimit() async throws {
        let (tracker, writer) = try makeTracker()

        for i in 0..<10 {
            tracker.log(TestError.withMessage("Error \(i)"))
        }
        await writer.flush()

        let recent = await tracker.recentErrors(limit: 3)
        #expect(recent.count == 3)
    }

    @Test("Log ErrorLog directly")
    func logErrorLogDirectly() async throws {
        let (tracker, writer) = try makeTracker()

        let errorLog = ErrorLog(
            domain: "com.test",
            code: 99,
            message: "Custom error log",
            errorType: "CustomError",
            fullDescription: "CustomError: Custom error log",
            severity: .warning
        )

        tracker.log(errorLog)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].domain == "com.test")
        #expect(errors[0].code == 99)
        #expect(errors[0].message == "Custom error log")
    }

    @Test("ErrorLog model properties")
    func errorLogProperties() {
        let now = Date()
        let errorLog = ErrorLog(
            timestamp: now,
            domain: "TestDomain",
            code: 1,
            message: "Test message",
            failureReason: "Test reason",
            recoverySuggestion: "Test suggestion",
            errorType: "TestType",
            userInfo: ["key": "value"],
            fullDescription: "Full description",
            severity: .critical,
            context: ["extra": "info"],
            callStackSymbols: ["frame1", "frame2"]
        )

        #expect(errorLog.category == .error)
        #expect(errorLog.timestamp == now)
        #expect(errorLog.domain == "TestDomain")
        #expect(errorLog.code == 1)
        #expect(errorLog.message == "Test message")
        #expect(errorLog.failureReason == "Test reason")
        #expect(errorLog.recoverySuggestion == "Test suggestion")
        #expect(errorLog.errorType == "TestType")
        #expect(errorLog.userInfo?["key"] == "value")
        #expect(errorLog.fullDescription == "Full description")
        #expect(errorLog.severity == .critical)
        #expect(errorLog.context?["extra"] == .string("info"))
        #expect(errorLog.callStackSymbols?.count == 2)
    }

    @Test("Log error with call stack capture")
    func logErrorWithCallStack() async throws {
        let (tracker, writer) = try makeTracker()

        tracker.log(TestError.simple, captureCallStack: true)
        await writer.flush()

        let errors = await tracker.recentErrors()
        #expect(errors.count == 1)
        #expect(errors[0].callStackSymbols != nil)
        #expect(errors[0].callStackSymbols!.count > 0)
    }
}
