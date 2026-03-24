import SwiftUI

/// Recursively renders a JSONValue tree using disclosure groups for containers.
@available(iOS 17, macOS 14, *)
struct JSONValueRows: View {
    let value: JSONValue
    let label: String? = nil

    var body: some View {
        switch value {
        case .array(let items):
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                JSONRow(label: "[\(index)]", value: item)
            }
        case .object(let pairs):
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                JSONRow(label: pair.key, value: pair.value)
            }
        default:
            leafRow(label: nil, value: value)
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct JSONRow: View {
    let label: String
    let value: JSONValue
    @State private var isExpanded: Bool

    init(label: String, value: JSONValue) {
        self.label = label
        self.value = value
        self._isExpanded = State(initialValue: value.hasContainerChildren)
    }

    var body: some View {
        if value.isContainer {
            DisclosureGroup(isExpanded: $isExpanded) {
                containerChildren(value)
            } label: {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.footnote.monospaced().weight(.semibold))
                    Text(value.summary)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } else {
            leafRow(label: label, value: value)
        }
    }

    @ViewBuilder
    private func containerChildren(_ val: JSONValue) -> some View {
        switch val {
        case .array(let items):
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                JSONRow(label: "[\(index)]", value: item)
            }
        case .object(let pairs):
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                JSONRow(label: pair.key, value: pair.value)
            }
        default:
            EmptyView()
        }
    }
}

@available(iOS 17, macOS 14, *)
private func leafRow(label: String?, value: JSONValue) -> some View {
    HStack(alignment: .top) {
        if let label {
            Text(label)
                .font(.footnote.monospaced().weight(.semibold))
        }
        Spacer()
        Text(value.summary)
            .font(.footnote.monospaced())
            .foregroundStyle(leafColor(value))
            .multilineTextAlignment(.trailing)
            .textSelection(.enabled)
    }
}

private func leafColor(_ value: JSONValue) -> Color {
    switch value {
    case .string: .green
    case .number: .blue
    case .bool: .orange
    case .null: .secondary
    default: .primary
    }
}
