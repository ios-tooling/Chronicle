import SwiftUI

/// Filter controls for the Chronicle viewer.
struct ChronicleFilterBar: View {
    @Bindable var model: ChronicleViewerModel

    var body: some View {
        VStack(spacing: 12) {
            Picker("Time Range", selection: $model.showCurrentRunOnly) {
                Text("Current Run").tag(true)
                Text("All History").tag(false)
            }
            .pickerStyle(.segmented)
            .onChange(of: model.showCurrentRunOnly) { model.refresh() }

            HStack(spacing: 8) {
                ForEach(EntryCategory.allCases, id: \.self) { category in
                    CategoryToggle(category: category, isSelected: model.isSelected(category), count: model.entryCounts[category] ?? 0) {
                        model.toggleCategory(category)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? category.tintColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(isSelected ? category.tintColor : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName): \(count)")
    }
}
