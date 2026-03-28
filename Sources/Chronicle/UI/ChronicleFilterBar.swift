import SwiftUI

/// Category filter controls for the Chronicle viewer.
@available(iOS 17, macOS 14, *)
struct ChronicleFilterBar: View {
    var model: ChronicleViewerModel
    let entries: [any ChronicleEntry]

    private var visibleCategories: [EntryCategory] {
        var categories = EntryCategory.builtIn
        let customInEntries = Set(entries.map(\.category)).subtracting(EntryCategory.builtIn)
        let customRegistered = Set(EntryCategory.allRegistered).subtracting(EntryCategory.builtIn)
        categories.append(contentsOf: customInEntries.union(customRegistered).sorted { $0.rawValue < $1.rawValue })
        return categories
    }

    private var entryCounts: [EntryCategory: Int] {
        var counts: [EntryCategory: Int] = [:]
        for entry in entries { counts[entry.category, default: 0] += 1 }
        return counts
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visibleCategories.filter { entryCounts[$0, default: 0] > 0 }, id: \.self) { category in
                    CategoryToggle(category: category, isSelected: model.isSelected(category), count: entryCounts[category] ?? 0) {
                        model.toggleCategory(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct CategoryToggle: View {
    let category: EntryCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.systemImage)
                    .font(.body)
                Text("\(count)")
                    .font(.caption2)
            }
            .frame(minWidth: 60)
            .padding(.vertical, 8)
            .background(isSelected ? category.tintColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(isSelected ? category.tintColor : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName): \(count)")
    }
}
