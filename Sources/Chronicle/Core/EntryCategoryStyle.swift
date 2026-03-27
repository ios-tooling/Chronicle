import SwiftUI

/// Display style for a Chronicle entry category.
public struct EntryCategoryStyle: Sendable {
    public let displayName: String
    public let systemImage: String
    public let tintColor: Color
    public let rowView: (@MainActor @Sendable (any ChronicleEntry) -> AnyView)?
    public let detailView: (@MainActor @Sendable (any ChronicleEntry) -> AnyView)?

    public init(displayName: String, systemImage: String, tintColor: Color, rowView: (@MainActor @Sendable (any ChronicleEntry) -> AnyView)? = nil, detailView: (@MainActor @Sendable (any ChronicleEntry) -> AnyView)? = nil) {
        self.displayName = displayName
        self.systemImage = systemImage
        self.tintColor = tintColor
        self.rowView = rowView
        self.detailView = detailView
    }
}

// MARK: - Style Registry

extension EntryCategory {
    private static let _lock = NSLock()
    nonisolated(unsafe) private static var _styles: [EntryCategory: EntryCategoryStyle] = [
        .event: EntryCategoryStyle(displayName: "Events", systemImage: "bolt.fill", tintColor: .blue),
        .network: EntryCategoryStyle(displayName: "Network", systemImage: "network", tintColor: .green),
        .flow: EntryCategoryStyle(displayName: "Flow", systemImage: "arrow.triangle.swap", tintColor: .purple),
        .error: EntryCategoryStyle(displayName: "Errors", systemImage: "exclamationmark.triangle.fill", tintColor: .red),
        .cloudKitUpload: EntryCategoryStyle(displayName: "CK Uploads", systemImage: "icloud.and.arrow.up.fill", tintColor: .orange),
        .cloudKitDownload: EntryCategoryStyle(displayName: "CK Downloads", systemImage: "icloud.and.arrow.down.fill", tintColor: .blue),
    ]

    /// Registers a display style for a custom category.
    public static func registerStyle(_ style: EntryCategoryStyle, for category: EntryCategory) {
        _lock.withLock { _styles[category] = style }
    }

    /// The registered style for this category, or a default style.
    public var style: EntryCategoryStyle {
        Self._lock.withLock { Self._styles[self] } ?? EntryCategoryStyle(displayName: rawValue.capitalized, systemImage: "doc.text", tintColor: .gray)
    }

    /// All categories that have registered styles.
    public static var allRegistered: [EntryCategory] {
        _lock.withLock { Array(_styles.keys) }
    }
}

// MARK: - Convenience accessors

extension EntryCategory {
    public var displayName: String { style.displayName }
    public var systemImage: String { style.systemImage }
    public var tintColor: Color { style.tintColor }
}
