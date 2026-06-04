import Foundation

/// Serializes Chronicle writes onto the storage actor.
///
/// Entries are enqueued synchronously (fire-and-forget) and drained in FIFO
/// order by a single background task, so breadcrumb and flow ordering is
/// preserved while callers never have to `await`.
@available(iOS 17, macOS 14, *)
final class StorageWriter: Sendable {
    private enum Command {
        case store(any ChronicleEntry)
        case flush(CheckedContinuation<Void, Never>)
    }

    private let continuation: AsyncStream<Command>.Continuation

    init(storage: SwiftDataStorage) {
        let (stream, continuation) = AsyncStream<Command>.makeStream()
        self.continuation = continuation
        Task {
            for await command in stream {
                switch command {
                case .store(let entry): await storage.store(entry)
                case .flush(let resume): resume.resume()
                }
            }
        }
    }

    /// Enqueues an entry to be persisted. Returns immediately.
    func store(_ entry: any ChronicleEntry) {
        continuation.yield(.store(entry))
    }

    /// Suspends until all previously enqueued writes have been persisted.
    func flush() async {
        await withCheckedContinuation { continuation.yield(.flush($0)) }
    }
}
