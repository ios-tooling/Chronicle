import SwiftUI

/// View model for the Chronicle entry viewer.
@Observable
public final class ChronicleViewerModel {
    var selectedCategories: Set<EntryCategory> = Set(EntryCategory.allCases)
    var showCurrentRunOnly = true
    var searchText = ""
    private(set) var entries: [any ChronicleEntry] = []

    public init() {}

    func refresh() {
        let since = showCurrentRunOnly ? Chronicle.instance.launchDate : nil
        let categories = selectedCategories.isEmpty ? nil : selectedCategories
        let nameFilter = searchText.isEmpty ? nil : searchText
        let query = StorageQuery(categories: categories, since: since, nameContains: nameFilter)
        entries = Chronicle.instance.entries(matching: query).reversed()
    }

    func toggleCategory(_ category: EntryCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        refresh()
    }

    func isSelected(_ category: EntryCategory) -> Bool {
        selectedCategories.contains(category)
    }

    func networkLog(for id: UUID?) -> NetworkLog? {
        guard let id else { return nil }
        return entries.first { $0.id == id } as? NetworkLog
    }

    var entryCounts: [EntryCategory: Int] {
        var counts: [EntryCategory: Int] = [:]
        for entry in entries {
            counts[entry.category, default: 0] += 1
        }
        return counts
    }
}
