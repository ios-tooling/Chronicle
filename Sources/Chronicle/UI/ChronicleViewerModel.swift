import SwiftUI
import SwiftData

/// View model for the Chronicle entry viewer. Holds filter state only;
/// actual queries are driven by @Query in ChronicleQueryContent.
@available(iOS 17, macOS 14, *)
@Observable
@MainActor
public final class ChronicleViewerModel {
    public var selectedCategories: Set<EntryCategory> = []
    public var selectedTags: Set<Tag> = []
    public var showCurrentRunOnly = true
    public var showTags = true
    public var searchText = ""

    public let modelContext: ModelContext
    public let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    public convenience init() {
        guard let container = Chronicle.instance.modelContainer else {
            fatalError("Chronicle must be configured before creating ChronicleViewerModel")
        }
        self.init(modelContainer: container)
    }

    func toggleCategory(_ category: EntryCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func isSelected(_ category: EntryCategory) -> Bool {
        selectedCategories.contains(category)
    }

    func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}
