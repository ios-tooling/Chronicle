import SwiftUI

/// Category filter controls for the Chronicle viewer.
struct ChronicleFilterBar: View {
    @Bindable var model: ChronicleViewerModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.visibleCategories, id: \.self) { category in
                    CategoryToggle(category: category, isSelected: model.isSelected(category), count: model.entryCounts[category] ?? 0) {
                        model.toggleCategory(category)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

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
