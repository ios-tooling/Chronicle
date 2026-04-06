import Foundation
import SwiftData
import Combine

/// Watches a Chronicle database for changes by polling modification dates.
///
/// FSEvents and kqueue are both unreliable for sandboxed apps watching paths
/// outside their own container (e.g. simulator app containers). Polling the
/// modification date of the db and WAL files is simple and always works.
@MainActor
final class DatabaseWatcher: ObservableObject {
    let modelContainer: ModelContainer
    @Published var refreshToken = UUID()

    private let dbURL: URL
    private var walURL: URL { URL(fileURLWithPath: dbURL.path + "-wal") }
    private var timer: Timer?
    private var lastKnownDate: Date?

    init(dbURL: URL, modelContainer: ModelContainer) {
        self.dbURL = dbURL
        self.modelContainer = modelContainer
        lastKnownDate = latestModificationDate()
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    func manualRefresh() {
        refreshToken = UUID()
    }

    // MARK: - Private

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let current = latestModificationDate()
        guard current != lastKnownDate else { return }
        print("[DatabaseWatcher] 📁 change detected (mod date: \(current?.description ?? "nil"))")
        lastKnownDate = current
        refreshToken = UUID()
    }

    private func latestModificationDate() -> Date? {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey]
        let dbDate = (try? dbURL.resourceValues(forKeys: keys))?.contentModificationDate
        let walDate = (try? walURL.resourceValues(forKeys: keys))?.contentModificationDate
        switch (dbDate, walDate) {
        case (let d?, let w?): return max(d, w)
        case (let d?, nil):    return d
        case (nil, let w?):    return w
        default:               return nil
        }
    }
}
